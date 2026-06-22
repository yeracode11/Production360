from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.catalog import ProductListResponse, ProductOut, SyncResult, UnitOut
from app.services.catalog import (
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


@router.get("/units", response_model=list[UnitOut])
async def get_units(
    include_deleted: bool = Query(default=False),
    session: AsyncSession = Depends(get_db),
) -> list[UnitOut]:
    units = await list_units(session, include_deleted=include_deleted)
    return [UnitOut.model_validate(u) for u in units]


@router.get("/nomenclature/search", response_model=ProductListResponse)
async def search_nomenclature(
    q: str = Query(..., min_length=1, description="Поиск по названию, коду, артикулу"),
    active_only: bool = Query(default=True),
    stock_only: bool = Query(default=True),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_db),
) -> ProductListResponse:
    products, total = await list_products(
        session,
        search=q,
        active_only=active_only,
        include_groups=False,
        stock_only=stock_only,
        limit=limit,
        offset=offset,
    )
    items = [ProductOut.model_validate(product_to_out(p)) for p in products]
    return ProductListResponse(total=total, items=items)


@router.get("/products", response_model=ProductListResponse, deprecated=True)
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


@router.post("/sync/units", response_model=SyncResult)
async def sync_units_endpoint(
    payload: dict[str, Any],
    session: AsyncSession = Depends(get_db),
) -> SyncResult:
    data_type = payload.get("dataType")
    if data_type != "edinicaIzm":
        raise HTTPException(status_code=400, detail="Expected dataType=edinicaIzm")

    items = payload.get("data")
    if not isinstance(items, list):
        raise HTTPException(status_code=400, detail="Expected data array")

    upserted = await sync_units(session, items)
    return SyncResult(data_type=data_type, received=len(items), upserted=upserted)


@router.post("/sync/products", response_model=SyncResult)
async def sync_products_endpoint(
    payload: dict[str, Any],
    session: AsyncSession = Depends(get_db),
) -> SyncResult:
    data_type = payload.get("dataType")
    if data_type != "nomenklatura":
        raise HTTPException(status_code=400, detail="Expected dataType=nomenklatura")

    items = payload.get("data")
    if not isinstance(items, list):
        raise HTTPException(status_code=400, detail="Expected data array")

    upserted = await sync_products(session, items)
    return SyncResult(data_type=data_type, received=len(items), upserted=upserted)
