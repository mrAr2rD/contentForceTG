"""
Telegram Channel Parser
Использует Pyrogram для доступа к Client API
"""

import asyncio
from datetime import datetime
from typing import List, Dict, Any, Optional

from pyrogram import Client
from pyrogram.types import Message
from pyrogram.errors import (
    SessionPasswordNeeded,
    PhoneCodeInvalid,
    ChannelPrivate,
    UsernameNotOccupied
)


class TelegramChannelParser:
    """
    Парсер истории Telegram каналов через Pyrogram
    """

    def __init__(
        self,
        api_id: int,
        api_hash: str,
        session_string: str
    ):
        self.api_id = api_id
        self.api_hash = api_hash
        self.session_string = session_string
        self.client: Optional[Client] = None

    async def start(self):
        """Запустить клиент Pyrogram"""
        self.client = Client(
            name="channel_parser",
            api_id=self.api_id,
            api_hash=self.api_hash,
            session_string=self.session_string,
            in_memory=True
        )
        await self.client.start()

    async def stop(self):
        """Остановить клиент"""
        if self.client:
            await self.client.stop()

    async def get_channel_history(
        self,
        channel_username: str,
        limit: int = 1000
    ) -> List[Dict[str, Any]]:
        """
        Получить историю сообщений канала

        Args:
            channel_username: Username канала (без @)
            limit: Максимальное количество сообщений

        Returns:
            Список сообщений в формате словаря
        """
        if not self.client:
            raise RuntimeError("Client not started. Call start() first.")

        # Очищаем username от @
        username = channel_username.lstrip("@")

        try:
            # Получаем информацию о канале
            chat = await self.client.get_chat(username)

            posts = []
            async for message in self.client.get_chat_history(
                chat_id=chat.id,
                limit=limit
            ):
                post_data = await self._parse_message(message)
                if post_data:
                    posts.append(post_data)

            return posts

        except UsernameNotOccupied:
            raise ValueError(f"Канал @{username} не найден")
        except ChannelPrivate:
            raise ValueError(f"Канал @{username} приватный или вы не являетесь участником")

    async def get_channel_info(
        self,
        channel_username: str
    ) -> Dict[str, Any]:
        """
        Получить информацию о канале (подписчики, название и т.д.)

        Args:
            channel_username: Username канала (без @)

        Returns:
            Информация о канале
        """
        if not self.client:
            raise RuntimeError("Client not started. Call start() first.")

        # Очищаем username от @
        username = channel_username.lstrip("@")

        try:
            # Получаем информацию о канале
            chat = await self.client.get_chat(username)

            # Получаем количество участников
            members_count = chat.members_count or 0

            return {
                "id": chat.id,
                "title": chat.title,
                "username": chat.username,
                "members_count": members_count,
                "description": chat.description,
                "type": str(chat.type) if chat.type else "channel"
            }

        except UsernameNotOccupied:
            raise ValueError(f"Канал @{username} не найден")
        except ChannelPrivate:
            raise ValueError(f"Канал @{username} приватный или вы не являетесь участником")

    async def get_messages_stats(
        self,
        channel_username: str,
        message_ids: List[int]
    ) -> List[Dict[str, Any]]:
        """
        Получить статистику конкретных сообщений по их ID

        Args:
            channel_username: Username канала (без @)
            message_ids: Список ID сообщений

        Returns:
            Список статистики сообщений
        """
        if not self.client:
            raise RuntimeError("Client not started. Call start() first.")

        # Очищаем username от @
        username = channel_username.lstrip("@")

        try:
            # Получаем информацию о канале
            chat = await self.client.get_chat(username)

            results = []
            # Получаем сообщения по ID (батчами по 100)
            for i in range(0, len(message_ids), 100):
                batch_ids = message_ids[i:i + 100]
                messages = await self.client.get_messages(
                    chat_id=chat.id,
                    message_ids=batch_ids
                )

                for message in messages:
                    if message and not message.empty:
                        results.append({
                            "message_id": int(message.id) if message.id else 0,
                            "views": int(message.views) if message.views else 0,
                            "forwards": int(message.forwards) if message.forwards else 0,
                            "reactions": self._parse_reactions(message.reactions) if message.reactions else {}
                        })
                    else:
                        # Сообщение не найдено или удалено
                        msg_id = batch_ids[messages.index(message)] if message in messages else 0
                        results.append({
                            "message_id": msg_id,
                            "views": 0,
                            "forwards": 0,
                            "reactions": {},
                            "not_found": True
                        })

            return results

        except UsernameNotOccupied:
            raise ValueError(f"Канал @{username} не найден")
        except ChannelPrivate:
            raise ValueError(f"Канал @{username} приватный или вы не являетесь участником")

    def _parse_reactions(self, reactions) -> Dict[str, int]:
        """Преобразовать реакции сообщения в словарь"""
        result = {}
        if reactions and hasattr(reactions, 'reactions'):
            for reaction in reactions.reactions:
                if hasattr(reaction, 'emoji') and reaction.emoji:
                    result[reaction.emoji] = int(reaction.count) if hasattr(reaction, 'count') else 0
                elif hasattr(reaction, 'custom_emoji_id'):
                    result[f"custom:{reaction.custom_emoji_id}"] = int(reaction.count) if hasattr(reaction, 'count') else 0
        return result

    async def _parse_message(self, message: Message) -> Optional[Dict[str, Any]]:
        """
        Преобразовать сообщение Pyrogram в словарь
        """
        # Пропускаем служебные сообщения
        if message.service:
            return None

        # Пропускаем сообщения без текста и без медиа
        if not message.text and not message.caption and not message.media:
            return None

        # Собираем текст
        text = message.text or message.caption or ""

        # Собираем медиа
        media = []
        if message.photo:
            media.append({
                "type": "photo",
                "file_id": message.photo.file_id,
                "url": None  # URL нужно получать отдельно через get_file
            })
        elif message.video:
            media.append({
                "type": "video",
                "file_id": message.video.file_id,
                "duration": message.video.duration,
                "url": None
            })
        elif message.document:
            media.append({
                "type": "document",
                "file_id": message.document.file_id,
                "file_name": message.document.file_name,
                "url": None
            })
        elif message.audio:
            media.append({
                "type": "audio",
                "file_id": message.audio.file_id,
                "duration": message.audio.duration,
                "url": None
            })

        return {
            "message_id": int(message.id) if message.id is not None else 0,
            "date": int(message.date.timestamp()) if message.date else None,
            "text": str(text) if text else "",
            "views": int(message.views) if message.views else 0,
            "forwards": int(message.forwards) if message.forwards else 0,
            "media": media,
            "has_media_spoiler": bool(message.has_media_spoiler) if hasattr(message, "has_media_spoiler") else False,
            "entities": self._parse_entities(message.entities or message.caption_entities or [])
        }

    def _parse_entities(self, entities) -> List[Dict[str, Any]]:
        """Преобразовать entities сообщения"""
        result = []
        for entity in entities:
            try:
                # Pyrogram's MessageEntityType - получаем строковое значение
                if hasattr(entity.type, 'name'):
                    entity_type = entity.type.name.lower()
                elif hasattr(entity.type, 'value') and isinstance(entity.type.value, str):
                    entity_type = entity.type.value
                else:
                    entity_type = str(entity.type)
            except Exception:
                entity_type = "unknown"

            result.append({
                "type": entity_type,
                "offset": int(entity.offset) if entity.offset is not None else 0,
                "length": int(entity.length) if entity.length is not None else 0,
                "url": str(entity.url) if hasattr(entity, "url") and entity.url else None
            })
        return result


class SessionGenerator:
    """
    Генератор session_string для Pyrogram
    Используется для авторизации пользователя
    """

    def __init__(self, api_id: int, api_hash: str):
        self.api_id = api_id
        self.api_hash = api_hash

    async def generate_session(self, phone_number: str) -> str:
        """
        Генерировать session_string через интерактивную авторизацию

        Note: Это требует ввода кода из Telegram,
        поэтому должно выполняться интерактивно
        """
        client = Client(
            name="session_generator",
            api_id=self.api_id,
            api_hash=self.api_hash,
            in_memory=True
        )

        await client.connect()

        try:
            sent_code = await client.send_code(phone_number)

            # Здесь нужен интерактивный ввод кода
            phone_code = input("Введите код из Telegram: ")

            try:
                await client.sign_in(
                    phone_number=phone_number,
                    phone_code_hash=sent_code.phone_code_hash,
                    phone_code=phone_code
                )
            except SessionPasswordNeeded:
                password = input("Введите пароль 2FA: ")
                await client.check_password(password)

            session_string = await client.export_session_string()
            return session_string

        finally:
            await client.disconnect()
