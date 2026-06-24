# Production360 Backend

PostgreSQL + FastAPI: **синк каталога из 1С** и **поиск для мобилки**.

## Публичный URL (1С и мобилка)

**`https://p360.darasoft.kz`** — все внешние запросы только сюда.

| Кто | URL |
|-----|-----|
| 1С синк единиц | `POST https://p360.darasoft.kz/sync/units` |
| 1С синк номенклатуры | `POST https://p360.darasoft.kz/sync/products` |
| Мобилка поиск | `GET https://p360.darasoft.kz/nomenclature/search?q=...` |
| Проверка | `GET https://p360.darasoft.kz/health` (без токена) |

### Авторизация (Bearer)

Все endpoint **кроме `/health`** требуют заголовок:

```http
Authorization: Bearer <API_BEARER_TOKEN>
```

Токен задаётся в `backend/.env` на сервере:

```env
API_BEARER_TOKEN=ваш-длинный-секрет
```

Сгенерировать: `openssl rand -hex 32`

Тот же токен — в мобилке `lib/core/config/catalog_config.dart` → `bearerToken`.

`localhost` в `.env` — **только внутри сервера** (FastAPI подключается к Postgres в docker). Снаружи его не используют.

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

## Деплой на сервер (p360.darasoft.kz)

### 1. Диагностика (если curl не работает)

```bash
# API локально на сервере
curl http://127.0.0.1:8000/health

# DNS домена → должен быть IP сервера (213.148.3.220)
dig +short p360.darasoft.kz

# Кто слушает 80/443
ss -tlnp | grep -E ':80|:443|:8000'
```

`Couldn't connect to port 443` = **нет nginx/SSL** или DNS не на этот сервер.

### 2. Postgres + таблицы

```bash
cd ~/Production360/backend
docker compose up -d
source .venv/bin/activate
python scripts/init_db.py
```

### 3. API (systemd)

```bash
cp deploy/production360-api.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now production360-api
systemctl status production360-api
curl http://127.0.0.1:8000/health
```

### 4. Nginx + HTTPS

```bash
apt install -y nginx certbot python3-certbot-nginx
cp deploy/nginx-p360.conf /etc/nginx/sites-available/p360
ln -sf /etc/nginx/sites-available/p360 /etc/nginx/sites-enabled/p360
nginx -t && systemctl reload nginx
certbot --nginx -d p360.darasoft.kz
```

### 5. Проверка снаружи

```bash
curl https://p360.darasoft.kz/health
```

### Bearer не работает — диагностика на сервере

```bash
cd /root/Production360/backend

# 1. Токен реально загружен в приложение (длина > 0)
.venv/bin/python -c "from app.config import settings; print(len(settings.api_bearer_token))"

# 2. В логах после restart должно быть: API bearer auth enabled (token length=...)
journalctl -u production360-api -n 30 --no-pager

# 3. Прямо на uvicorn (минуя nginx) — без токена 401, с токеном 200
TOKEN=$(grep '^API_BEARER_TOKEN=' .env | cut -d= -f2-)
curl -s -o /dev/null -w "%{http_code}\n" "http://127.0.0.1:8000/nomenclature/search?q=test"
curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $TOKEN" \
  "http://127.0.0.1:8000/nomenclature/search?q=test"

# 4. Через nginx — если (3) ок, а здесь 401 с тем же токеном — обновите nginx:
#    в deploy/nginx-p360.conf есть proxy_set_header Authorization $http_authorization;
nginx -t && systemctl reload nginx
```

Формат `.env` — **без кавычек** и пробелов вокруг `=`:

```env
API_BEARER_TOKEN=a1b2c3d4e5f6...
```

В `curl` URL всегда в кавычках; кириллицу в `q` кодировать:

```bash
curl -s -G -H "Authorization: Bearer $TOKEN" --data-urlencode "q=банан" \
  "https://p360.darasoft.kz/nomenclature/search"
```

## Локальный dev

```bash
cd backend
docker compose up -d
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Создать таблицы:

```bash
python scripts/init_db.py
```

## API для мобилки

| Метод | Путь |
|-------|------|
| GET | `/health` |
| GET | `/nomenclature/search?q=банан` | Поиск: не удалённые, не группы, только `Запас`, `q_active` |
