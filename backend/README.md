# Production360 Backend

PostgreSQL + FastAPI: **синк номенклатуры из 1С** и **поиск для мобилки**.

Заказы, авторизация, типы заявок — **в 1С**. Каталог — **здесь**.

## Схема

```
1С разработчик ──POST /sync/units, /sync/products──►  PostgreSQL
Мобилка ──GET /nomenclature/search?q=──►  Backend
Мобилка ──auth, заказы, type/data──────►  1С
```

## Для разработчика 1С (синк)

Отправляйте JSON выгрузки на наш API:

| Метод | URL | `dataType` в body |
|-------|-----|-------------------|
| POST | `{BASE_URL}/sync/units` | `edinicaIzm` |
| POST | `{BASE_URL}/sync/products` | `nomenklatura` |

Формат body:

```json
{
  "dataType": "nomenklatura",
  "data": [ { "Ссылка": "...", "Код": "...", "Наименование": "...", ... } ]
}
```

Поля — как в обмене 1С (`Ссылка`, `Код`, `Наименование`, `ЕдиницаИзмерения`, `Комментарий`, `ТипНоменклатуры`, …).

Синк **upsert по `Ссылка`** (id). Мобилка не дергает 1С для поиска — только этот backend после синка.

## Запуск (dev)

```bash
cd backend
cp .env.example .env
docker compose up -d
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Проверка синка вручную (тот же формат, что шлёт 1С):

```bash
python scripts/sync_catalog.py path/to/export.json
```

## API для мобилки

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/health` | Проверка |
| GET | `/nomenclature/search?q=банан` | Поиск (обязательный `q`) |

Параметры поиска: `active_only=true`, `stock_only=true` (только «Запас»), `limit`, `offset`.

## БД

`units`, `products` — `app/models/catalog.py`.

## Следующий шаг

- Прод URL в `CatalogConfig` (Flutter)
- Auth на sync/search API
- Периодический синк из 1С (cron / webhook)
