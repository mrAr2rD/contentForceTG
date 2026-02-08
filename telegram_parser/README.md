# Telegram Channel Parser

Микросервис для парсинга истории Telegram каналов через Pyrogram (Client API).

## Требования

- Python 3.11+
- `api_id` и `api_hash` от [my.telegram.org](https://my.telegram.org)
- Авторизованная сессия Telegram (session_string)

## Установка

```bash
cd telegram_parser
python -m venv venv
source venv/bin/activate  # или venv\Scripts\activate на Windows
pip install -r requirements.txt
```

## Настройка

1. Скопируйте `.env.example` в `.env`
2. Укажите `TELEGRAM_API_ID` и `TELEGRAM_API_HASH`

```bash
cp .env.example .env
```

## Запуск

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## Docker

```bash
docker build -t telegram-parser .
docker run -p 8000:8000 --env-file .env telegram-parser
```

## API

### POST /sync

Запуск синхронизации канала.

**Request:**
```json
{
  "channel_site_id": "uuid",
  "channel_username": "channelname",
  "session_string": "pyrogram_session_string",
  "callback_url": "https://app.contentforce.app/webhooks/channel_sync",
  "limit": 1000
}
```

**Response:**
```json
{
  "status": "started",
  "message": "Синхронизация канала channelname запущена"
}
```

### GET /health

Health check.

**Response:**
```json
{
  "status": "ok",
  "service": "telegram-parser"
}
```

## Генерация session_string

Для парсинга каналов нужна авторизованная сессия Telegram.
Session string генерируется через интерактивный скрипт:

```python
import asyncio
from parser import SessionGenerator

async def main():
    generator = SessionGenerator(
        api_id=YOUR_API_ID,
        api_hash="YOUR_API_HASH"
    )
    session = await generator.generate_session("+79001234567")
    print(f"Session string: {session}")

asyncio.run(main())
```

Сохраните `session_string` в безопасном месте — это эквивалент логина в Telegram.
