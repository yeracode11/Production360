-- Оптимизация каталога: индексы, organization_ids, кэш групп.
-- Запуск на сервере:
--   psql "$DATABASE_URL" -f scripts/optimize_catalog.sql
-- Затем:
--   python scripts/rebuild_catalog_cache.py

CREATE EXTENSION IF NOT EXISTS pg_trgm;

ALTER TABLE products
    ADD COLUMN IF NOT EXISTS organization_ids text[];

CREATE TABLE IF NOT EXISTS catalog_visible_groups (
    id SERIAL PRIMARY KEY,
    organization_key VARCHAR(64) NOT NULL,
    parent_id UUID NULL,
    group_id UUID NOT NULL,
    CONSTRAINT uq_catalog_visible_groups UNIQUE (organization_key, parent_id, group_id)
);

CREATE INDEX IF NOT EXISTS ix_catalog_visible_groups_lookup
    ON catalog_visible_groups (organization_key, parent_id);

CREATE INDEX IF NOT EXISTS ix_products_organization_ids
    ON products USING GIN (organization_ids);

CREATE INDEX IF NOT EXISTS ix_products_browse_products
    ON products (parent_id, is_deleted, is_group, show_in_mobile_app, comment, product_type)
    WHERE is_deleted = false AND is_group = false;

CREATE INDEX IF NOT EXISTS ix_products_browse_groups
    ON products (parent_id, is_deleted, is_group)
    WHERE is_deleted = false AND is_group = true;

CREATE INDEX IF NOT EXISTS ix_products_name_trgm
    ON products USING GIN (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS ix_products_code_trgm
    ON products USING GIN (code gin_trgm_ops);

CREATE INDEX IF NOT EXISTS ix_products_article_trgm
    ON products USING GIN (article gin_trgm_ops)
    WHERE article IS NOT NULL;

-- organization_ids: NULL = все организации; [] = не привязан.
UPDATE products
SET organization_ids = NULL
WHERE usage_places IS NULL
   OR jsonb_typeof(usage_places::jsonb) <> 'array'
   OR COALESCE(jsonb_array_length(usage_places::jsonb), 0) = 0;

UPDATE products p
SET organization_ids = sub.org_ids
FROM (
    SELECT
        id,
        ARRAY_AGG(DISTINCT lower(elem->>'id')) AS org_ids
    FROM products,
         jsonb_array_elements(usage_places::jsonb) AS elem
    WHERE usage_places IS NOT NULL
      AND jsonb_typeof(usage_places::jsonb) = 'array'
      AND COALESCE(jsonb_array_length(usage_places::jsonb), 0) > 0
      AND elem->>'type' = 'organization'
      AND COALESCE(elem->>'id', '') <> ''
    GROUP BY id
) AS sub
WHERE p.id = sub.id;

UPDATE products
SET organization_ids = '{}'::text[]
WHERE usage_places IS NOT NULL
  AND jsonb_typeof(usage_places::jsonb) = 'array'
  AND COALESCE(jsonb_array_length(usage_places::jsonb), 0) > 0
  AND organization_ids IS NULL;
