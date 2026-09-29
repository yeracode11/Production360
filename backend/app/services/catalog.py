import uuid
from typing import Any

from sqlalchemy import Text, cast, delete, exists, func, or_, select
from sqlalchemy.dialects.postgresql import ARRAY, insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import CatalogVisibleGroup, Product, Unit
from app.models.catalog_cache import UNIVERSAL_ORG_KEY

ACTIVE_PRODUCT_COMMENT = "q_active"
STOCK_PRODUCT_TYPE = "Запас"
# 1С часто шлёт «пустого родителя» как нулевой UUID вместо null.
EMPTY_PARENT_UUID = uuid.UUID(int=0)


def _parse_uuid(value: Any) -> uuid.UUID | None:
    if value is None or value == "":
        return None
    return uuid.UUID(str(value))


def _parse_parent_id(value: Any) -> uuid.UUID | None:
    parent_id = _parse_uuid(value)
    if parent_id == EMPTY_PARENT_UUID:
        return None
    return parent_id


def _parse_unit_id(value: Any) -> uuid.UUID | None:
    """1С иногда шлёт пустую единицу измерения нулевым UUID."""
    unit_id = _parse_uuid(value)
    if unit_id == EMPTY_PARENT_UUID:
        return None
    return unit_id


def _is_root_parent(parent_id: uuid.UUID | None) -> bool:
    return parent_id is None or parent_id == EMPTY_PARENT_UUID


def _normalize_parent_id(parent_id: uuid.UUID | None) -> uuid.UUID | None:
    if parent_id is None or parent_id == EMPTY_PARENT_UUID:
        return None
    return parent_id


def _extract_organization_ids(
    usage_places: list[dict[str, str]] | None,
) -> list[str] | None:
    """NULL — для всех организаций; [] — не привязан ни к одной."""
    if usage_places is None:
        return None
    if not usage_places:
        return None

    org_ids: list[str] = []
    seen: set[str] = set()
    for place in usage_places:
        if str(place.get("type") or "").strip().lower() != "organization":
            continue
        org_id = str(place.get("id") or "").strip().lower()
        if not org_id or org_id in seen:
            continue
        seen.add(org_id)
        org_ids.append(org_id)
    return org_ids if org_ids else []


def _organization_filter(organization_id: str | None):
    org_id = (organization_id or "").strip().lower()
    if not org_id:
        return None
    return or_(
        Product.organization_ids.is_(None),
        Product.organization_ids.contains(cast([org_id], ARRAY(Text))),
    )


def _visible_group_org_keys(organization_ids: list[str] | None) -> list[str]:
    if organization_ids is None:
        return [UNIVERSAL_ORG_KEY]
    if not organization_ids:
        return []
    return [org_id.lower() for org_id in organization_ids]


def _visible_group_parent_filter(
    *,
    parent_id: uuid.UUID | None,
    parent_is_root: bool,
):
    if parent_is_root:
        return CatalogVisibleGroup.parent_id.is_(None)
    if parent_id is not None:
        return CatalogVisibleGroup.parent_id == parent_id
    return CatalogVisibleGroup.parent_id.is_(None)


async def backfill_organization_ids(session: AsyncSession) -> int:
    """Заполнить organization_ids из usage_places для существующих строк."""
    result = await session.execute(select(Product.id, Product.usage_places))
    updated = 0
    for product_id, usage_places in result.all():
        if usage_places is None or not isinstance(usage_places, list):
            org_ids = None
        else:
            org_ids = _extract_organization_ids(usage_places)

        await session.execute(
            Product.__table__.update()
            .where(Product.id == product_id)
            .values(organization_ids=org_ids)
        )
        updated += 1

    await session.commit()
    return updated


async def rebuild_catalog_visible_groups(session: AsyncSession) -> int:
    """Пересчитать кэш групп с мобильной номенклатурой (вызывается после sync)."""
    await session.execute(delete(CatalogVisibleGroup))

    group_rows = await session.execute(
        select(Product.id, Product.parent_id).where(
            Product.is_group.is_(True),
            Product.is_deleted.is_(False),
        )
    )
    parent_by_group: dict[uuid.UUID, uuid.UUID | None] = {
        group_id: _normalize_parent_id(parent_id)
        for group_id, parent_id in group_rows.all()
    }

    product_rows = await session.execute(
        select(Product.parent_id, Product.organization_ids).where(
            Product.is_deleted.is_(False),
            Product.is_group.is_(False),
            Product.show_in_mobile_app.is_(True),
            Product.comment == ACTIVE_PRODUCT_COMMENT,
            Product.product_type == STOCK_PRODUCT_TYPE,
        )
    )

    entries: set[tuple[str, uuid.UUID | None, uuid.UUID]] = set()
    for parent_id, organization_ids in product_rows.all():
        org_keys = _visible_group_org_keys(organization_ids)
        if not org_keys:
            continue

        group_id = _normalize_parent_id(parent_id)
        while group_id is not None and group_id in parent_by_group:
            group_parent = parent_by_group[group_id]
            for org_key in org_keys:
                entries.add((org_key, group_parent, group_id))
            group_id = group_parent

    if entries:
        await session.execute(
            insert(CatalogVisibleGroup),
            [
                {
                    "organization_key": org_key,
                    "parent_id": group_parent,
                    "group_id": group_id,
                }
                for org_key, group_parent, group_id in entries
            ],
        )

    await session.commit()
    return len(entries)


def _parse_bool(value: Any, default: bool = False) -> bool:
    if isinstance(value, bool):
        return value
    if value is None:
        return default
    normalized = str(value).strip().lower()
    if normalized in {"1", "true", "yes", "да"}:
        return True
    if normalized in {"0", "false", "no", "нет"}:
        return False
    return default


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
                "updated_at": func.now(),
            },
        )
        await session.execute(stmt)
        upserted += 1

    await session.commit()
    return upserted


def _parse_usage_places(raw: Any) -> list[dict[str, str]]:
    if raw is None:
        return []
    if isinstance(raw, dict):
        raw = [raw]
    if not isinstance(raw, list):
        return []

    places: list[dict[str, str]] = []
    seen: set[str] = set()
    for entry in raw:
        if not isinstance(entry, dict):
            continue
        place_type = str(entry.get("type") or "").strip()
        place_id = str(entry.get("id") or "").strip()
        name = str(entry.get("name") or "").strip()
        if not name:
            continue
        dedupe_key = place_id if place_id else f"{place_type}|{name}"
        if dedupe_key in seen:
            continue
        seen.add(dedupe_key)
        places.append({"type": place_type, "id": place_id, "name": name})
    return places


async def sync_products(session: AsyncSession, items: list[dict[str, Any]]) -> int:
    upserted = 0
    for raw in items:
        product_id = _parse_uuid(raw.get("Ссылка"))
        if product_id is None:
            continue

        has_mobile_flag = "ОтображатьВМобильнымПриложении" in raw
        has_usage_places = "МестаИспользования" in raw

        values = {
            "id": product_id,
            "parent_id": _parse_parent_id(raw.get("Родитель")),
            "is_group": _parse_bool(raw.get("ЭтоГруппа")),
            "code": str(raw.get("Код") or "").strip(),
            "name": str(raw.get("Наименование") or "").strip(),
            "full_name": _empty_to_none(raw.get("НаименованиеПолное")),
            "article": _empty_to_none(raw.get("Артикул")),
            "unit_id": _parse_unit_id(raw.get("ЕдиницаИзмерения")),
            "product_type": _empty_to_none(raw.get("ТипНоменклатуры")),
            "barcode": _empty_to_none(raw.get("Штрихкод")),
            "comment": _empty_to_none(raw.get("Комментарий")),
            "predefined_name": _empty_to_none(raw.get("ИмяПредопределенныхДанных")),
            "is_deleted": _parse_bool(raw.get("ПометкаУдаления")),
            "show_in_mobile_app": _parse_bool(
                raw.get("ОтображатьВМобильнымПриложении"),
                default=False,
            )
            if has_mobile_flag
            else False,
            "usage_places": _parse_usage_places(raw.get("МестаИспользования"))
            if has_usage_places
            else None,
        }
        if has_usage_places:
            values["organization_ids"] = _extract_organization_ids(values["usage_places"])
        update_fields = {
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
            "updated_at": func.now(),
        }
        if has_mobile_flag:
            update_fields["show_in_mobile_app"] = values["show_in_mobile_app"]
        if has_usage_places:
            update_fields["usage_places"] = values["usage_places"]
            update_fields["organization_ids"] = values["organization_ids"]
        stmt = insert(Product).values(**values)
        stmt = stmt.on_conflict_do_update(
            index_elements=[Product.id],
            set_=update_fields,
        )
        await session.execute(stmt)
        upserted += 1

    await session.commit()
    await rebuild_catalog_visible_groups(session)
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
    search: str | None = None,
    organization_id: str,
    parent_id: uuid.UUID | None = None,
    parent_is_root: bool = False,
    groups_only: bool = False,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[Product], int]:
    """Список/поиск для мобилки.

    С ``q`` — глобальный поиск товаров (игнорирует parent/groups).
    С ``groups_only`` — папки номенклатуры по ``parent_id`` / корню.
    Иначе — товары-запасы внутри выбранной группы.
    """
    if search and search.strip():
        return await list_products(
            session,
            search=search,
            organization_id=organization_id,
            active_only=True,
            include_groups=False,
            include_deleted=False,
            stock_only=True,
            mobile_only=True,
            limit=limit,
            offset=offset,
        )

    if groups_only:
        return await list_products(
            session,
            organization_id=organization_id,
            parent_id=parent_id,
            parent_is_root=parent_is_root,
            groups_only=True,
            include_deleted=False,
            active_only=False,
            stock_only=False,
            limit=limit,
            offset=offset,
        )

    return await list_products(
        session,
        organization_id=organization_id,
        parent_id=parent_id,
        parent_is_root=parent_is_root,
        active_only=True,
        include_groups=False,
        include_deleted=False,
        stock_only=True,
        mobile_only=True,
        limit=limit,
        offset=offset,
    )


async def list_products(
    session: AsyncSession,
    *,
    search: str | None = None,
    organization_id: str | None = None,
    parent_id: uuid.UUID | None = None,
    parent_is_root: bool = False,
    groups_only: bool = False,
    active_only: bool = True,
    include_groups: bool = False,
    include_deleted: bool = False,
    stock_only: bool = True,
    mobile_only: bool = False,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[Product], int]:
    org_id = (organization_id or "").strip().lower()
    org_filter = _organization_filter(organization_id)

    if groups_only:
        visible_group_exists = (
            select(1)
            .select_from(CatalogVisibleGroup)
            .where(CatalogVisibleGroup.group_id == Product.id)
            .where(
                _visible_group_parent_filter(
                    parent_id=parent_id,
                    parent_is_root=parent_is_root,
                )
            )
        )
        if org_id:
            visible_group_exists = visible_group_exists.where(
                CatalogVisibleGroup.organization_key.in_([org_id, UNIVERSAL_ORG_KEY])
            )

        stmt = (
            select(Product)
            .where(Product.is_deleted.is_(False))
            .where(Product.is_group.is_(True))
            .where(exists(visible_group_exists))
        )
    else:
        stmt = select(Product).where(Product.is_deleted.is_(False))
        if not include_groups:
            stmt = stmt.where(Product.is_group.is_(False))

        if parent_is_root:
            stmt = stmt.where(
                or_(
                    Product.parent_id.is_(None),
                    Product.parent_id == EMPTY_PARENT_UUID,
                )
            )
        elif parent_id is not None:
            stmt = stmt.where(Product.parent_id == parent_id)

        if active_only:
            stmt = stmt.where(Product.comment == ACTIVE_PRODUCT_COMMENT)
        if stock_only:
            stmt = stmt.where(Product.product_type == STOCK_PRODUCT_TYPE)
        if mobile_only:
            stmt = stmt.where(Product.show_in_mobile_app.is_(True))
        if org_filter is not None:
            stmt = stmt.where(org_filter)

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
    usage_places = product.usage_places if isinstance(product.usage_places, list) else []
    return {
        "id": product.id,
        "name": product.name,
        "code": product.code,
        "article": product.article,
        "edIzm": unit_short,
        "unit_id": product.unit_id,
        "is_group": product.is_group,
        "parentId": str(product.parent_id) if product.parent_id else None,
        "is_deleted": product.is_deleted,
        "is_active": product.comment == ACTIVE_PRODUCT_COMMENT and not product.is_deleted,
        "product_type": product.product_type,
        "barcode": product.barcode,
        "showInMobileApp": product.show_in_mobile_app,
        "usagePlaces": usage_places,
    }


def _empty_to_none(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text if text else None
