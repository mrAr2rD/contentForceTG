"""
Telegram Channel Parser Microservice
Парсит историю Telegram каналов через Pyrogram (Client API)
"""

import os
import asyncio
from datetime import datetime
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
import httpx

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


class SyncRequest(BaseModel):
    """Запрос на синхронизацию канала"""
    channel_site_id: str
    channel_username: str
    session_string: str
    callback_url: str
    limit: Optional[int] = 1000


class SyncResponse(BaseModel):
    """Ответ на запрос синхронизации"""
    status: str
    message: str


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok", "service": "telegram-parser"}


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
        request.channel_username,
        request.session_string,
        request.callback_url,
        request.limit
    )

    return SyncResponse(
        status="started",
        message=f"Синхронизация канала {request.channel_username} запущена"
    )


async def process_channel_sync(
    channel_site_id: str,
    channel_username: str,
    session_string: str,
    callback_url: str,
    limit: int
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

        # Отправляем результаты в Rails
        await send_callback(callback_url, {
            "channel_site_id": channel_site_id,
            "status": "success",
            "posts": posts
        })

    except Exception as e:
        # Отправляем ошибку
        await send_callback(callback_url, {
            "channel_site_id": channel_site_id,
            "status": "error",
            "error": str(e)
        })
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
