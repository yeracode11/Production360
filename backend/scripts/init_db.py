#!/usr/bin/env python3
"""Создать таблицы units и products в PostgreSQL."""

import asyncio
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.database import engine
from app.models import CatalogVisibleGroup, Product, Unit  # noqa: F401 — регистрация моделей
from app.models.base import Base


async def main() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await engine.dispose()
    print("OK: tables created (units, products, catalog_visible_groups)")


if __name__ == "__main__":
    asyncio.run(main())
