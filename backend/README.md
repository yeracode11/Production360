# Production360 Backend

PostgreSQL + FastAPI: **синк каталога из 1С** и **поиск для мобилки**.

## Схема

```
1С ──POST /sync/units, /sync/products──►  PostgreSQL (upsert)
Мобилка ──GET /nomenclature/search?q=──►  Backend
Мобилка ──auth, заказы, type/data──────►  1С
```

## Для разработчика 1С — два endpoint синка

Базовый URL: `https://p360.darasoft.kz`

| Метод | Путь | `dataType` в body |
|-------|------|-------------------|
| POST | `/sync/units` | `edinicaIzm` |
| POST | `/sync/products` | `nomenklatura` |

Создание и замена — **upsert по полю `Ссылка`** (UUID).

### Единицы измерения

`POST /sync/units`

```json
{
  "dataType": "edinicaIzm",
  "data": [
    {
      "Ссылка": "08f0b406-cace-11f0-96c8-3cecef963ddd",
      "Код": "796",
      "Наименование": "шт",
      "НаименованиеПолное": "Штука",
      "ПометкаУдаления": false
    }
  ]
}
```

### Номенклатура

`POST /sync/products`

```json
{
  "dataType": "nomenklatura",
  "data": [
    {
      "Ссылка": "a1a27397-cbc5-11f0-96c8-3cecef963ddd",
      "Код": "НФ-00001210",
      "Наименование": "ВАФЕЛЬНАЯ тряпка",
      "ЕдиницаИзмерения": "08f0b406-cace-11f0-96c8-3cecef963ddd",
      "Комментарий": "q_active",
      "ТипНоменклатуры": "Запас",
      "ПометкаУдаления": false,
      "ЭтоГруппа": false
    }
  ]
}
```

**Ответ (для обоих):**

```json
{ "data_type": "nomenklatura", "received": 300, "upserted": 300 }
```

## Запуск

```bash
cd backend
docker compose up -d
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Создать таблицы вручную (если API ещё не запускали):

```bash
source .venv/bin/activate
python scripts/init_db.py
```

## API для мобилки

| Метод | Путь |
|-------|------|
| GET | `/health` |
| GET | `/nomenclature/search?q=банан` |
