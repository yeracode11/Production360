from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.auth import require_api_token
from app.config import settings
from app.database import get_db
from app.schemas.catalog import ProductListResponse, ProductOut, SyncResult, UnitOut
from app.services.catalog import (
    list_nomenclature_search,
    list_products,
    list_units,
    product_to_out,
    sync_products,
    sync_units,
)

router = APIRouter(tags=["catalog"])


@router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/app/version")
async def app_version() -> dict[str, str]:
    """Минимальные версии мобильного приложения для force update."""
    return {
        "min_version": settings.min_app_version,
        "min_version_ios": settings.min_app_version_ios,
        "min_version_android": settings.min_app_version_android,
    }


@router.get("/units", response_model=list[UnitOut], dependencies=[Depends(require_api_token)])
async def get_units(
    include_deleted: bool = Query(default=False),
    session: AsyncSession = Depends(get_db),
) -> list[UnitOut]:
    units = await list_units(session, include_deleted=include_deleted)
    return [UnitOut.model_validate(u) for u in units]


@router.get(
    "/nomenclature/search",
    response_model=ProductListResponse,
    dependencies=[Depends(require_api_token)],
)
async def search_nomenclature(
    q: str = Query(..., min_length=1, description="Поиск по названию, коду, артикулу"),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_db),
) -> ProductListResponse:
    """Только: is_deleted=false, is_group=false, product_type=Запас, comment=q_active."""
    products, total = await list_nomenclature_search(
        session,
        search=q,
        limit=limit,
        offset=offset,
    )
    items = [ProductOut.model_validate(product_to_out(p)) for p in products]
    return ProductListResponse(total=total, items=items)


@router.get(
    "/products",
    response_model=ProductListResponse,
    deprecated=True,
    dependencies=[Depends(require_api_token)],
)
async def get_products_legacy(
    search: str = Query(..., min_length=1),
    active_only: bool = Query(default=True),
    stock_only: bool = Query(default=True),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_db),
) -> ProductListResponse:
    """Совместимость: используйте GET /nomenclature/search."""
    products, total = await list_products(
        session,
        search=search,
        active_only=active_only,
        include_groups=False,
        stock_only=stock_only,
        limit=limit,
        offset=offset,
    )
    items = [ProductOut.model_validate(product_to_out(p)) for p in products]
    return ProductListResponse(total=total, items=items)


@router.post("/sync/units", response_model=SyncResult, dependencies=[Depends(require_api_token)])
async def sync_units_endpoint(
    payload: dict[str, Any],
    session: AsyncSession = Depends(get_db),
) -> SyncResult:
    """Синк единиц измерения из 1С (upsert по «Ссылка»). dataType=edinicaIzm."""
    data_type = payload.get("dataType")
    if data_type != "edinicaIzm":
        raise HTTPException(status_code=400, detail="Expected dataType=edinicaIzm")

    items = payload.get("data")
    if not isinstance(items, list):
        raise HTTPException(status_code=400, detail="Expected data array")

    upserted = await sync_units(session, items)
    return SyncResult(data_type=data_type, received=len(items), upserted=upserted)


@router.post("/sync/products", response_model=SyncResult, dependencies=[Depends(require_api_token)])
async def sync_products_endpoint(
    payload: dict[str, Any],
    session: AsyncSession = Depends(get_db),
) -> SyncResult:
    """Синк номенклатуры из 1С (upsert по «Ссылка»). dataType=nomenklatura."""
    data_type = payload.get("dataType")
    if data_type != "nomenklatura":
        raise HTTPException(status_code=400, detail="Expected dataType=nomenklatura")

    items = payload.get("data")
    if not isinstance(items, list):
        raise HTTPException(status_code=400, detail="Expected data array")

    upserted = await sync_products(session, items)
    return SyncResult(data_type=data_type, received=len(items), upserted=upserted)
