"""
Telegram Channel Parser Microservice
Парсит историю Telegram каналов через Pyrogram (Client API)
"""

import os
import asyncio
from datetime import datetime
from typing import Optional, Dict, Any
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

    try:
        await client.sign_in(
            phone_number=phone,
            phone_code_hash=request.phone_code_hash,
            phone_code=request.phone_code
        )

        # Успешная авторизация - получаем session_string
        session_string = await client.export_session_string()
        await client.disconnect()
        del auth_clients[phone]

        return VerifyCodeResponse(
            success=True,
            session_string=session_string
        )

    except SessionPasswordNeeded:
        # Нужна 2FA - сохраняем клиент
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


@app.post("/sync", response_model=SyncResponse)
async def sync_channel(request: SyncRequest, background_tasks: BackgroundTasks):
    """
    Запустить синхронизацию канала в фоне
    """
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
    parser = None
    try:
        parser = TelegramChannelParser(
            api_id=int(API_ID),
            api_hash=API_HASH,
            session_string=session_string
        )

        await parser.start()

        # Получаем историю канала
        posts = await parser.get_channel_history(channel_username, limit=limit)

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
        await send_callback(callback_url, callback_data)

    except Exception as e:
        # Отправляем ошибку
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


async def send_callback(url: str, data: dict):
    """Отправить результаты в callback URL"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                url,
                json=data,
                timeout=30.0
            )
            response.raise_for_status()
        except Exception as e:
            print(f"Failed to send callback: {e}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
