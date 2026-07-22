-- Исправление usage_places: скаляр/объект → пустой массив (ломает jsonb_array_length).
UPDATE products
SET usage_places = '[]'::json
WHERE usage_places IS NOT NULL
  AND jsonb_typeof(usage_places::jsonb) <> 'array';
