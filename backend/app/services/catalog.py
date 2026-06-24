import uuid
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Product, Unit

ACTIVE_PRODUCT_COMMENT = "q_active"
STOCK_PRODUCT_TYPE = "Запас"


def _parse_uuid(value: Any) -> uuid.UUID | None:
    if value is None or value == "":
        return None
    return uuid.UUID(str(value))


def _parse_bool(value: Any, default: bool = False) -> bool:
    if isinstance(value, bool):
        return value
    if value is None:
        return default
    return str(value).lower() in {"1", "true", "yes"}


async def sync_units(session: AsyncSession, items: list[dict[str, Any]]) -> int:
    upserted = 0
    for raw in items:
        unit_id = _parse_uuid(raw.get("Ссылка"))
        if unit_id is None:
            continue

        values = {
            "id": unit_id,
            "code": str(raw.get("Код") or "").strip(),
            "short_name": str(raw.get("Наименование") or "").strip(),
            "full_name": str(raw.get("НаименованиеПолное") or "").strip(),
            "predefined_name": _empty_to_none(raw.get("ИмяПредопределенныхДанных")),
            "is_deleted": _parse_bool(raw.get("ПометкаУдаления")),
        }
        stmt = insert(Unit).values(**values)
        stmt = stmt.on_conflict_do_update(
            index_elements=[Unit.id],
            set_={
                "code": values["code"],
                "short_name": values["short_name"],
                "full_name": values["full_name"],
                "predefined_name": values["predefined_name"],
                "is_deleted": values["is_deleted"],
            },
        )
        await session.execute(stmt)
        upserted += 1

    await session.commit()
    return upserted


async def sync_products(session: AsyncSession, items: list[dict[str, Any]]) -> int:
    upserted = 0
    for raw in items:
        product_id = _parse_uuid(raw.get("Ссылка"))
        if product_id is None:
            continue

        values = {
            "id": product_id,
            "parent_id": _parse_uuid(raw.get("Родитель")),
            "is_group": _parse_bool(raw.get("ЭтоГруппа")),
            "code": str(raw.get("Код") or "").strip(),
            "name": str(raw.get("Наименование") or "").strip(),
            "full_name": _empty_to_none(raw.get("НаименованиеПолное")),
            "article": _empty_to_none(raw.get("Артикул")),
            "unit_id": _parse_uuid(raw.get("ЕдиницаИзмерения")),
            "product_type": _empty_to_none(raw.get("ТипНоменклатуры")),
            "barcode": _empty_to_none(raw.get("Штрихкод")),
            "comment": _empty_to_none(raw.get("Комментарий")),
            "predefined_name": _empty_to_none(raw.get("ИмяПредопределенныхДанных")),
            "is_deleted": _parse_bool(raw.get("ПометкаУдаления")),
        }
        stmt = insert(Product).values(**values)
        stmt = stmt.on_conflict_do_update(
            index_elements=[Product.id],
            set_={
                "parent_id": values["parent_id"],
                "is_group": values["is_group"],
                "code": values["code"],
                "name": values["name"],
                "full_name": values["full_name"],
                "article": values["article"],
                "unit_id": values["unit_id"],
                "product_type": values["product_type"],
                "barcode": values["barcode"],
                "comment": values["comment"],
                "predefined_name": values["predefined_name"],
                "is_deleted": values["is_deleted"],
            },
        )
        await session.execute(stmt)
        upserted += 1

    await session.commit()
    return upserted


async def list_units(session: AsyncSession, include_deleted: bool = False) -> list[Unit]:
    stmt = select(Unit).order_by(Unit.short_name)
    if not include_deleted:
        stmt = stmt.where(Unit.is_deleted.is_(False))
    result = await session.execute(stmt)
    return list(result.scalars().all())


async def list_nomenclature_search(
    session: AsyncSession,
    *,
    search: str,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[Product], int]:
    """Поиск для мобилки: не удалённые, не группы, только «Запас», активные (q_active)."""
    return await list_products(
        session,
        search=search,
        active_only=True,
        include_groups=False,
        include_deleted=False,
        stock_only=True,
        limit=limit,
        offset=offset,
    )


async def list_products(
    session: AsyncSession,
    *,
    search: str | None = None,
    active_only: bool = True,
    include_groups: bool = False,
    include_deleted: bool = False,
    stock_only: bool = True,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[Product], int]:
    stmt = select(Product)

    if not include_deleted:
        stmt = stmt.where(Product.is_deleted.is_(False))
    if not include_groups:
        stmt = stmt.where(Product.is_group.is_(False))
    if active_only:
        stmt = stmt.where(Product.comment == ACTIVE_PRODUCT_COMMENT)
    if stock_only:
        stmt = stmt.where(Product.product_type == STOCK_PRODUCT_TYPE)

    if search:
        pattern = f"%{search.strip()}%"
        stmt = stmt.where(
            Product.name.ilike(pattern)
            | Product.code.ilike(pattern)
            | Product.article.ilike(pattern)
        )

    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = int((await session.execute(count_stmt)).scalar_one())

    stmt = stmt.order_by(Product.name).limit(limit).offset(offset)
    result = await session.execute(stmt)
    products = list(result.scalars().unique().all())
    return products, total


def product_to_out(product: Product) -> dict[str, Any]:
    unit_short = product.unit.short_name if product.unit else None
    return {
        "id": product.id,
        "name": product.name,
        "code": product.code,
        "article": product.article,
        "edIzm": unit_short,
        "unit_id": product.unit_id,
        "is_group": product.is_group,
        "is_deleted": product.is_deleted,
        "is_active": product.comment == ACTIVE_PRODUCT_COMMENT and not product.is_deleted,
        "product_type": product.product_type,
        "barcode": product.barcode,
    }


def _empty_to_none(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text if text else None
