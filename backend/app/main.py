import logging

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes.catalog import router
from app.config import settings
from app.database import engine
from app.models import CatalogVisibleGroup, Product, Unit  # noqa: F401
from app.models.base import Base
from app.services.catalog_rebuild import flush_catalog_rebuild

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    token_len = len(settings.api_bearer_token)
    if token_len == 0:
        logger.warning("API_BEARER_TOKEN is empty — protected routes return 503")
    else:
        logger.info("API bearer auth enabled (token length=%d)", token_len)
    if settings.sync_bearer_token:
        logger.info(
            "SYNC_BEARER_TOKEN set (length=%d): /sync/* %s",
            len(settings.sync_bearer_token),
            "also accepts API_BEARER_TOKEN (transition mode)"
            if settings.sync_accept_legacy_token
            else "rejects API_BEARER_TOKEN",
        )
    else:
        logger.warning(
            "SYNC_BEARER_TOKEN is empty — /sync/* accepts API_BEARER_TOKEN "
            "(the token shipped in the mobile app). Set SYNC_BEARER_TOKEN."
        )

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    await flush_catalog_rebuild()
    await engine.dispose()


def create_app() -> FastAPI:
    app = FastAPI(
        title="Production360 API",
        description="Каталог номенклатуры и единиц измерения (синк с 1С)",
        version="0.1.0",
        lifespan=lifespan,
    )

    origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins if origins != ["*"] else ["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(router)
    return app


app = create_app()
