from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class UnitOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    short_name: str
    full_name: str
    is_deleted: bool


class ProductOut(BaseModel):
    """Формат близкий к мобильному API (products в type/data)."""

    id: UUID
    name: str
    code: str
    article: str | None = None
    edIzm: str | None = None
    unit_id: UUID | None = None
    is_group: bool
    is_deleted: bool
    is_active: bool
    product_type: str | None = None
    barcode: str | None = None


class ProductListResponse(BaseModel):
    total: int
    items: list[ProductOut]


class SyncResult(BaseModel):
    data_type: str
    received: int
    upserted: int
