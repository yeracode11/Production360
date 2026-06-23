#!/usr/bin/env python3
"""Создать таблицы units и products в PostgreSQL."""

import asyncio

from app.database import engine
from app.models import Product, Unit  # noqa: F401 — регистрация моделей
from app.models.base import Base


async def main() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await engine.dispose()
    print("OK: tables created (units, products)")


if __name__ == "__main__":
    asyncio.run(main())
