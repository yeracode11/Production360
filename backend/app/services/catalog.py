import uuid
from typing import Any

from sqlalchemy import func, or_, select, text
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Product, Unit

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


def _is_root_parent(parent_id: uuid.UUID | None) -> bool:
    return parent_id is None or parent_id == EMPTY_PARENT_UUID


def _mobile_child_exists_sql(parent_column: str, organization_id: str | None) -> str:
    org_id = (organization_id or "").strip()
    org_clause = (
        "child.usage_places IS NULL "
        "OR jsonb_typeof(child.usage_places::jsonb) <> 'array' "
        "OR COALESCE(jsonb_array_length(child.usage_places::jsonb), 0) = 0 "
        "OR EXISTS ("
        "  SELECT 1 FROM jsonb_array_elements(child.usage_places::jsonb) elem "
        "  WHERE elem->>'type' = 'organization' "
        "  AND lower(elem->>'id') = lower(:org_id)"
        ")"
        if org_id
        else "TRUE"
    )
    return (
        "EXISTS ("
        "SELECT 1 FROM products child "
        f"WHERE child.parent_id = {parent_column} "
        "AND child.is_deleted = false "
        "AND child.is_group = false "
        "AND child.show_in_mobile_app = true "
        "AND child.comment = :active_comment "
        "AND child.product_type = :stock_type "
        f"AND ({org_clause})"
        ")"
    )


def _non_empty_group_condition(organization_id: str | None):
    """Группа не пустая: есть товар для мобилки или непустая подгруппа."""
    mobile_at_level = _mobile_child_exists_sql("products.id", organization_id)
    mobile_in_subgroup = _mobile_child_exists_sql("child.id", organization_id)
    subgroup_with_content = (
        "EXISTS ("
        "SELECT 1 FROM products child "
        "WHERE child.parent_id = products.id "
        "AND child.is_deleted = false "
        "AND child.is_group = true "
        f"AND (({mobile_in_subgroup}) OR EXISTS ("
        "  SELECT 1 FROM products nested "
        "  WHERE nested.parent_id = child.id "
        "  AND nested.is_deleted = false "
        "  AND nested.is_group = true"
        "))"
        ")"
    )
    condition_sql = f"(({mobile_at_level}) OR ({subgroup_with_content}))"
    org_id = (organization_id or "").strip()
    if org_id:
        return text(condition_sql).bindparams(
            org_id=org_id,
            active_comment=ACTIVE_PRODUCT_COMMENT,
            stock_type=STOCK_PRODUCT_TYPE,
        )
    return text(condition_sql).bindparams(
        active_comment=ACTIVE_PRODUCT_COMMENT,
        stock_type=STOCK_PRODUCT_TYPE,
    )


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
            "unit_id": _parse_uuid(raw.get("ЕдиницаИзмерения")),
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
        stmt = insert(Product).values(**values)
        stmt = stmt.on_conflict_do_update(
            index_elements=[Product.id],
            set_=update_fields,
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
    stmt = select(Product)

    if not include_deleted:
        stmt = stmt.where(Product.is_deleted.is_(False))

    if groups_only:
        stmt = stmt.where(Product.is_group.is_(True))
        stmt = stmt.where(_non_empty_group_condition(organization_id))
    elif not include_groups:
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
    if organization_id:
        org_id = organization_id.strip()
        stmt = stmt.where(
            or_(
                Product.usage_places.is_(None),
                text(
                    "jsonb_typeof(products.usage_places::jsonb) <> 'array' "
                    "OR COALESCE(jsonb_array_length(products.usage_places::jsonb), 0) = 0"
                ),
                text(
                    "jsonb_typeof(products.usage_places::jsonb) = 'array' AND EXISTS ("
                    "SELECT 1 FROM jsonb_array_elements(products.usage_places::jsonb) AS elem "
                    "WHERE elem->>'type' = 'organization' "
                    "AND lower(elem->>'id') = lower(:org_id)"
                    ")"
                ).bindparams(org_id=org_id),
            )
        )

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
