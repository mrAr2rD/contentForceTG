"""
Telegram Channel Parser Microservice
Парсит историю Telegram каналов через Pyrogram (Client API)
"""

import os
import asyncio
import json
from datetime import datetime
from typing import Optional, Dict, Any, List
import time

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
import httpx
from pyrogram import Client
from pyrogram.errors import (
    SessionPasswordNeeded,
    PhoneCodeInvalid,
    PhoneCodeExpired,
    FloodWait,
    PasswordHashInvalid
)

from parser import TelegramChannelParser

load_dotenv()

app = FastAPI(
    title="Telegram Channel Parser",
    description="Microservice для парсинга истории Telegram каналов",
    version="1.0.0"
)

# Конфигурация
API_ID = os.getenv("TELEGRAM_API_ID")
API_HASH = os.getenv("TELEGRAM_API_HASH")

# Хранилище активных клиентов для авторизации (in-memory, с TTL)
# Структура: {phone_number: {"client": Client, "expires_at": timestamp}}
auth_clients: Dict[str, Dict[str, Any]] = {}
AUTH_TTL = 300  # 5 минут


def cleanup_expired_clients():
    """Удалить устаревшие клиенты авторизации"""
    now = time.time()
    expired = [phone for phone, data in auth_clients.items() if data["expires_at"] < now]
    for phone in expired:
        try:
            asyncio.create_task(auth_clients[phone]["client"].disconnect())
        except:
            pass
        del auth_clients[phone]


class SyncRequest(BaseModel):
    """Запрос на синхронизацию канала"""
    channel_site_id: Optional[str] = None
    project_id: Optional[str] = None
    channel_username: str
    session_string: str
    callback_url: str
    limit: Optional[int] = 1000
    import_type: Optional[str] = "channel_site"  # channel_site или style_samples


class SyncResponse(BaseModel):
    """Ответ на запрос синхронизации"""
    status: str
    message: str


class SendCodeRequest(BaseModel):
    """Запрос на отправку кода"""
    phone_number: str


class SendCodeResponse(BaseModel):
    """Ответ на отправку кода"""
    success: bool
    phone_code_hash: Optional[str] = None
    error: Optional[str] = None


class VerifyCodeRequest(BaseModel):
    """Запрос на проверку кода"""
    phone_number: str
    phone_code_hash: str
    phone_code: str


class VerifyCodeResponse(BaseModel):
    """Ответ на проверку кода"""
    success: bool
    session_string: Optional[str] = None
    requires_2fa: bool = False
    error: Optional[str] = None


class Verify2FARequest(BaseModel):
    """Запрос на проверку 2FA"""
    phone_number: str
    password: str


class Verify2FAResponse(BaseModel):
    """Ответ на проверку 2FA"""
    success: bool
    session_string: Optional[str] = None
    error: Optional[str] = None


class MessageStatsRequest(BaseModel):
    """Запрос на получение статистики сообщений"""
    channel_username: str
    message_ids: List[int]
    session_string: str


class MessageStatsResponse(BaseModel):
    """Ответ со статистикой сообщений"""
    success: bool
    stats: Optional[List[Dict[str, Any]]] = None
    error: Optional[str] = None


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    cleanup_expired_clients()
    return {"status": "ok", "service": "telegram-parser"}


@app.post("/auth/send-code", response_model=SendCodeResponse)
async def send_code(request: SendCodeRequest):
    """
    Отправить код авторизации на номер телефона
    """
    print(f"[AUTH] send_code called for phone: {request.phone_number}")
    print(f"[AUTH] API_ID: {API_ID}, API_HASH: {'set' if API_HASH else 'not set'}")

    if not API_ID or not API_HASH:
        return SendCodeResponse(
            success=False,
            error="TELEGRAM_API_ID и TELEGRAM_API_HASH не настроены"
        )

    cleanup_expired_clients()
    phone = request.phone_number.strip()

    # Создаём клиент
    client = Client(
        name=f"auth_{phone.replace('+', '')}",
        api_id=int(API_ID),
        api_hash=API_HASH,
        in_memory=True
    )

    try:
        await client.connect()
        sent_code = await client.send_code(phone)

        # Сохраняем клиент в память
        auth_clients[phone] = {
            "client": client,
            "phone_code_hash": sent_code.phone_code_hash,
            "expires_at": time.time() + AUTH_TTL
        }

        print(f"[AUTH] Code sent successfully, phone_code_hash: {sent_code.phone_code_hash[:10]}...")
        print(f"[AUTH] Active clients: {list(auth_clients.keys())}")

        return SendCodeResponse(
            success=True,
            phone_code_hash=sent_code.phone_code_hash
        )

    except FloodWait as e:
        await client.disconnect()
        return SendCodeResponse(
            success=False,
            error=f"Слишком много попыток. Подождите {e.value} секунд"
        )
    except Exception as e:
        await client.disconnect()
        return SendCodeResponse(
            success=False,
            error=str(e)
        )


@app.post("/auth/verify-code", response_model=VerifyCodeResponse)
async def verify_code(request: VerifyCodeRequest):
    """
    Проверить код авторизации
    """
    print(f"[AUTH] verify_code called for phone: {request.phone_number}")
    print(f"[AUTH] Active clients before cleanup: {list(auth_clients.keys())}")

    cleanup_expired_clients()
    phone = request.phone_number.strip()

    print(f"[AUTH] Active clients after cleanup: {list(auth_clients.keys())}")
    print(f"[AUTH] Looking for phone: {phone}")

    if phone not in auth_clients:
        print(f"[AUTH] ERROR: Phone {phone} not found in auth_clients!")
        return VerifyCodeResponse(
            success=False,
            error="Сессия авторизации истекла. Запросите код заново"
        )

    client_data = auth_clients[phone]
    client = client_data["client"]

    print(f"[AUTH] Calling sign_in for {phone} with code {request.phone_code}")

    try:
        result = await client.sign_in(
            phone_number=phone,
            phone_code_hash=request.phone_code_hash,
            phone_code=request.phone_code
        )
        print(f"[AUTH] sign_in result: {result}")

        # Успешная авторизация - получаем session_string
        session_string = await client.export_session_string()
        print(f"[AUTH] SUCCESS! Got session_string for {phone}")
        await client.disconnect()
        del auth_clients[phone]

        return VerifyCodeResponse(
            success=True,
            session_string=session_string
        )

    except SessionPasswordNeeded:
        # Нужна 2FA - сохраняем клиент
        print(f"[AUTH] 2FA required for {phone}")
        auth_clients[phone]["requires_2fa"] = True
        return VerifyCodeResponse(
            success=False,
            requires_2fa=True
        )

    except PhoneCodeInvalid:
        print(f"[AUTH] ERROR: PhoneCodeInvalid for {phone}")
        return VerifyCodeResponse(
            success=False,
            error="Неверный код. Попробуйте ещё раз"
        )

    except PhoneCodeExpired:
        print(f"[AUTH] ERROR: PhoneCodeExpired for {phone}")
        await client.disconnect()
        del auth_clients[phone]
        return VerifyCodeResponse(
            success=False,
            error="Код истёк. Запросите новый"
        )

    except Exception as e:
        print(f"[AUTH] ERROR: Exception for {phone}: {type(e).__name__} - {e}")
        return VerifyCodeResponse(
            success=False,
            error=str(e)
        )


@app.post("/auth/verify-2fa", response_model=Verify2FAResponse)
async def verify_2fa(request: Verify2FARequest):
    """
    Проверить пароль двухфакторной аутентификации
    """
    cleanup_expired_clients()
    phone = request.phone_number.strip()

    if phone not in auth_clients:
        return Verify2FAResponse(
            success=False,
            error="Сессия авторизации истекла. Начните заново"
        )

    client_data = auth_clients[phone]
    client = client_data["client"]

    try:
        await client.check_password(request.password)

        # Успешная авторизация - получаем session_string
        session_string = await client.export_session_string()
        await client.disconnect()
        del auth_clients[phone]

        return Verify2FAResponse(
            success=True,
            session_string=session_string
        )

    except PasswordHashInvalid:
        return Verify2FAResponse(
            success=False,
            error="Неверный пароль 2FA"
        )

    except Exception as e:
        return Verify2FAResponse(
            success=False,
            error=str(e)
        )


@app.post("/message-stats", response_model=MessageStatsResponse)
async def get_message_stats(request: MessageStatsRequest):
    """
    Получить статистику (views, forwards, reactions) для конкретных сообщений
    """
    print(f"[STATS] Request for channel={request.channel_username}, message_ids={request.message_ids}")

    if not API_ID or not API_HASH:
        return MessageStatsResponse(
            success=False,
            error="TELEGRAM_API_ID и TELEGRAM_API_HASH не настроены"
        )

    if not request.message_ids:
        return MessageStatsResponse(
            success=False,
            error="message_ids не может быть пустым"
        )

    parser = None
    try:
        parser = TelegramChannelParser(
            api_id=int(API_ID),
            api_hash=API_HASH,
            session_string=request.session_string
        )

        await parser.start()

        stats = await parser.get_messages_stats(
            channel_username=request.channel_username,
            message_ids=request.message_ids
        )

        print(f"[STATS] Got stats for {len(stats)} messages")

        return MessageStatsResponse(
            success=True,
            stats=stats
        )

    except ValueError as e:
        print(f"[STATS] ValueError: {e}")
        return MessageStatsResponse(
            success=False,
            error=str(e)
        )
    except Exception as e:
        print(f"[STATS] Error: {type(e).__name__} - {e}")
        return MessageStatsResponse(
            success=False,
            error=str(e)
        )
    finally:
        if parser:
            await parser.stop()


@app.post("/sync", response_model=SyncResponse)
async def sync_channel(request: SyncRequest, background_tasks: BackgroundTasks):
    """
    Запустить синхронизацию канала в фоне
    """
    print(f"[SYNC] Request received: channel={request.channel_username}, import_type={request.import_type}")
    print(f"[SYNC] project_id={request.project_id}, callback_url={request.callback_url}")
    print(f"[SYNC] session_string present: {bool(request.session_string)}")

    if not API_ID or not API_HASH:
        raise HTTPException(
            status_code=500,
            detail="TELEGRAM_API_ID и TELEGRAM_API_HASH не настроены"
        )

    # Запускаем парсинг в фоне
    background_tasks.add_task(
        process_channel_sync,
        request.channel_site_id,
        request.project_id,
        request.channel_username,
        request.session_string,
        request.callback_url,
        request.limit,
        request.import_type
    )

    return SyncResponse(
        status="started",
        message=f"Синхронизация канала {request.channel_username} запущена"
    )


async def process_channel_sync(
    channel_site_id: Optional[str],
    project_id: Optional[str],
    channel_username: str,
    session_string: str,
    callback_url: str,
    limit: int,
    import_type: str
):
    """
    Фоновая задача: парсит канал и отправляет результаты в callback
    """
    print(f"[SYNC] Starting channel sync: {channel_username}")
    parser = None
    try:
        parser = TelegramChannelParser(
            api_id=int(API_ID),
            api_hash=API_HASH,
            session_string=session_string
        )

        print(f"[SYNC] Parser created, starting...")
        await parser.start()
        print(f"[SYNC] Parser started, fetching history...")

        # Получаем историю канала
        posts = await parser.get_channel_history(channel_username, limit=limit)
        print(f"[SYNC] Got {len(posts)} posts from {channel_username}")

        # Формируем данные в зависимости от типа импорта
        if import_type == "style_samples":
            # Для импорта стиля отправляем project_id и channel_username
            callback_data = {
                "project_id": project_id,
                "channel_username": channel_username,
                "status": "success",
                "posts": posts
            }
        else:
            # Для channel_site отправляем channel_site_id
            callback_data = {
                "channel_site_id": channel_site_id,
                "status": "success",
                "posts": posts
            }

        # Отправляем результаты в Rails
        print(f"[SYNC] Sending callback to {callback_url}")
        await send_callback(callback_url, callback_data)
        print(f"[SYNC] Callback sent successfully")

    except Exception as e:
        # Отправляем ошибку
        print(f"[SYNC] ERROR: {type(e).__name__} - {e}")
        error_data = {
            "status": "error",
            "error": str(e)
        }
        if import_type == "style_samples":
            error_data["project_id"] = project_id
        else:
            error_data["channel_site_id"] = channel_site_id

        await send_callback(callback_url, error_data)
    finally:
        if parser:
            await parser.stop()


def make_json_serializable(obj):
    """Рекурсивно преобразовать объект в JSON-сериализуемый формат"""
    if obj is None:
        return None
    if isinstance(obj, (str, int, float, bool)):
        return obj
    if isinstance(obj, (datetime,)):
        return obj.isoformat()
    if isinstance(obj, dict):
        return {str(k): make_json_serializable(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [make_json_serializable(item) for item in obj]
    if hasattr(obj, 'value'):
        # Enum
        return make_json_serializable(obj.value)
    if hasattr(obj, 'name') and hasattr(obj, '__class__'):
        # Enum by name
        return obj.name
    # Fallback - конвертируем в строку
    return str(obj)


async def send_callback(url: str, data: dict):
    """Отправить результаты в callback URL"""
    # Предварительно преобразуем данные в JSON-сериализуемый формат
    safe_data = make_json_serializable(data)

    # Проверяем сериализуемость перед отправкой
    try:
        json.dumps(safe_data)
    except (TypeError, ValueError) as e:
        print(f"[CALLBACK] JSON serialization test failed: {e}")
        print(f"[CALLBACK] Problematic data keys: {list(data.keys()) if isinstance(data, dict) else type(data)}")
        # Пробуем отправить без posts если проблема в них
        if isinstance(safe_data, dict) and 'posts' in safe_data:
            safe_data['posts'] = []
            safe_data['error'] = f"JSON serialization failed: {e}"

    async with httpx.AsyncClient() as client:
        try:
            print(f"[CALLBACK] Sending to {url}, posts count: {len(safe_data.get('posts', []))}")
            response = await client.post(
                url,
                json=safe_data,
                timeout=30.0
            )
            response.raise_for_status()
            print(f"[CALLBACK] Success, status: {response.status_code}")
        except Exception as e:
            print(f"[CALLBACK] Failed to send callback: {e}")
            print(f"[CALLBACK] callback_url={url}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
