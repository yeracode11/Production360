import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, String, func, text
from sqlalchemy.dialects.postgresql import ARRAY, JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class Unit(Base):
    __tablename__ = "units"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True)
    code: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    short_name: Mapped[str] = mapped_column(String(50), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    predefined_name: Mapped[str | None] = mapped_column(String(50), nullable=True)
    is_deleted: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    products: Mapped[list["Product"]] = relationship(
        back_populates="unit", foreign_keys="Product.unit_id"
    )


class Product(Base):
    __tablename__ = "products"
    __table_args__ = (
        Index(
            "ix_products_browse_products",
            "parent_id",
            "is_deleted",
            "is_group",
            "show_in_mobile_app",
            "comment",
            "product_type",
            postgresql_where=text("is_deleted = false AND is_group = false"),
        ),
        Index(
            "ix_products_browse_groups",
            "parent_id",
            "is_deleted",
            "is_group",
            postgresql_where=text("is_deleted = false AND is_group = true"),
        ),
        Index(
            "ix_products_organization_ids",
            "organization_ids",
            postgresql_using="gin",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True)
    parent_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True, index=True
    )
    is_group: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    code: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(500), nullable=False, index=True)
    full_name: Mapped[str | None] = mapped_column(String(500), nullable=True)
    article: Mapped[str | None] = mapped_column(String(100), nullable=True)
    unit_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("units.id"), nullable=True, index=True
    )
    product_type: Mapped[str | None] = mapped_column(String(50), nullable=True)
    barcode: Mapped[str | None] = mapped_column(String(100), nullable=True)
    comment: Mapped[str | None] = mapped_column(String(100), nullable=True, index=True)
    predefined_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    is_deleted: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    show_in_mobile_app: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, index=True
    )
    usage_places: Mapped[list | None] = mapped_column(JSON, nullable=True)
    organization_ids: Mapped[list[str] | None] = mapped_column(
        ARRAY(String(64)), nullable=True
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    unit: Mapped[Unit | None] = relationship(
        back_populates="products", lazy="joined", foreign_keys=[unit_id]
    )
