"""Отложенный пересчёт кэша групп (catalog_visible_groups) после синка.

1С шлёт номенклатуру пачками. Раньше каждая пачка пересчитывала кэш по
всему каталогу. Теперь пачки только помечают «нужен пересчёт», а сам
пересчёт выполняется один раз — через ``catalog_rebuild_debounce_seconds``
после последней пачки, в фоне, не задерживая ответ 1С.
"""

import asyncio
import logging

from app.config import settings
from app.database import async_session_factory
from app.services.catalog import rebuild_catalog_visible_groups

logger = logging.getLogger(__name__)

_pending = asyncio.Event()
_task: asyncio.Task[None] | None = None
_last_request: float = 0.0


async def _run_rebuild() -> None:
    async with async_session_factory() as session:
        entries = await rebuild_catalog_visible_groups(session)
    logger.info("catalog_visible_groups rebuilt: %d entries", entries)


async def _worker() -> None:
    loop = asyncio.get_running_loop()
    delay = max(settings.catalog_rebuild_debounce_seconds, 0.0)
    while _pending.is_set():
        # Ждём, пока поток пачек затихнет на `delay` секунд.
        while True:
            remaining = _last_request + delay - loop.time()
            if remaining <= 0:
                break
            await asyncio.sleep(remaining)
        _pending.clear()
        try:
            await _run_rebuild()
        except Exception:  # noqa: BLE001 — фон не должен умирать молча
            logger.exception("catalog_visible_groups rebuild failed; retrying later")
            _pending.set()
            await asyncio.sleep(max(delay, 5.0))


def _on_done(task: asyncio.Task[None]) -> None:
    global _task
    if _task is task:
        _task = None
    # Пачка могла прийти в момент завершения воркера.
    if _pending.is_set() and not task.cancelled():
        _ensure_worker()


def _ensure_worker() -> None:
    global _task
    if _task is None or _task.done():
        _task = asyncio.create_task(_worker(), name="catalog-rebuild")
        _task.add_done_callback(_on_done)


async def request_catalog_rebuild() -> None:
    """Вызвать после успешного синка номенклатуры."""
    global _last_request
    if settings.catalog_rebuild_debounce_seconds <= 0:
        await _run_rebuild()
        return
    _last_request = asyncio.get_running_loop().time()
    _pending.set()
    _ensure_worker()


async def flush_catalog_rebuild() -> None:
    """При остановке сервера: не терять отложенный пересчёт."""
    global _task
    task = _task
    _task = None
    interrupted = False
    if task is not None and not task.done():
        interrupted = True
        task.cancel()
        try:
            await task
        except asyncio.CancelledError:
            pass
    if _pending.is_set() or interrupted:
        _pending.clear()
        try:
            await _run_rebuild()
        except Exception:  # noqa: BLE001
            logger.exception("catalog_visible_groups rebuild on shutdown failed")
