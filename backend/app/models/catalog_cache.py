import uuid

from sqlalchemy import Index, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base

# Продукт без привязки к организации в usage_places — виден всем.
UNIVERSAL_ORG_KEY = "*"


class CatalogVisibleGroup(Base):
    """Предрасчёт: какие группы показывать в мобилке для org + parent."""

    __tablename__ = "catalog_visible_groups"
    __table_args__ = (
        UniqueConstraint(
            "organization_key",
            "parent_id",
            "group_id",
            name="uq_catalog_visible_groups",
        ),
        Index(
            "ix_catalog_visible_groups_lookup",
            "organization_key",
            "parent_id",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    organization_key: Mapped[str] = mapped_column(String(64), nullable=False)
    parent_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True
    )
    group_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
