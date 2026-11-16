"""Bearer-авторизация.

Два уровня доступа:

* чтение (каталог, единицы) — мобилка;
* запись (``/sync/*``) — только 1С.

Токены (``backend/.env``):

* ``API_BEARER_TOKEN`` — старый общий токен. Зашит в выпущенные версии
  мобилки, поэтому остаётся рабочим для чтения.
* ``SYNC_BEARER_TOKEN`` — токен 1С для ``/sync/*``. Пока он не задан,
  синк принимает ``API_BEARER_TOKEN`` (как раньше). Как только задан —
  ``API_BEARER_TOKEN`` для синка больше не подходит
  (кроме переходного режима ``SYNC_ACCEPT_LEGACY_TOKEN=true``).
"""

import secrets

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import settings

_bearer = HTTPBearer(auto_error=False)


def _matches(provided: str, expected: str) -> bool:
    if not expected:
        return False
    return secrets.compare_digest(provided.encode("utf-8"), expected.encode("utf-8"))


def _extract_token(credentials: HTTPAuthorizationCredentials | None) -> str:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization required: Bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return credentials.credentials.strip()


def _invalid_token() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid bearer token",
        headers={"WWW-Authenticate": "Bearer"},
    )


def read_tokens() -> list[str]:
    return [
        t
        for t in (
            settings.api_bearer_token,
            settings.mobile_bearer_token,
            settings.sync_bearer_token,
        )
        if t
    ]


def sync_tokens() -> list[str]:
    if not settings.sync_bearer_token:
        # Обратная совместимость: отдельный токен 1С ещё не настроен.
        return [settings.api_bearer_token] if settings.api_bearer_token else []
    tokens = [settings.sync_bearer_token]
    if settings.sync_accept_legacy_token and settings.api_bearer_token:
        tokens.append(settings.api_bearer_token)
    return tokens


async def require_api_token(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> None:
    """Доступ на чтение: мобилка и 1С."""
    allowed = read_tokens()
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="API_BEARER_TOKEN is not configured on server",
        )
    token = _extract_token(credentials)
    if not any(_matches(token, expected) for expected in allowed):
        raise _invalid_token()


async def require_sync_token(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> None:
    """Доступ на запись (/sync/*): только 1С."""
    allowed = sync_tokens()
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="SYNC_BEARER_TOKEN is not configured on server",
        )
    token = _extract_token(credentials)
    if any(_matches(token, expected) for expected in allowed):
        return
    if _matches(token, settings.api_bearer_token) or _matches(
        token, settings.mobile_bearer_token
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This token is read-only; use SYNC_BEARER_TOKEN for /sync",
        )
    raise _invalid_token()
