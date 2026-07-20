from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class UnitOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    short_name: str
    full_name: str
    is_deleted: bool


class UsagePlaceOut(BaseModel):
    type: str
    id: str
    name: str


class ProductOut(BaseModel):
    """Формат для мобилки: поиск номенклатуры (не заявки)."""

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
    showInMobileApp: bool = False
    usagePlaces: list[UsagePlaceOut] = Field(default_factory=list)


class ProductListResponse(BaseModel):
    total: int
    items: list[ProductOut]


class SyncResult(BaseModel):
    data_type: str
    received: int
    upserted: int
