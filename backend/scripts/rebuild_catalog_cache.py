#!/usr/bin/env python3
"""Backfill organization_ids и пересборка catalog_visible_groups."""

import asyncio

from app.database import async_session_factory, engine
from app.models import CatalogVisibleGroup, Product  # noqa: F401
from app.services.catalog import backfill_organization_ids, rebuild_catalog_visible_groups


async def main() -> None:
    async with async_session_factory() as session:
        updated = await backfill_organization_ids(session)
        entries = await rebuild_catalog_visible_groups(session)
    await engine.dispose()
    print(f"OK: organization_ids updated={updated}, visible_groups={entries}")


if __name__ == "__main__":
    asyncio.run(main())
