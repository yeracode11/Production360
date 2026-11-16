from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = (
        "postgresql+asyncpg://production360:production360@localhost:5432/production360"
    )
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    cors_origins: str = "*"
    # Старый общий токен (зашит в мобилку). После настройки SYNC_BEARER_TOKEN — только чтение.
    api_bearer_token: str = ""
    # Новый токен мобилки только на чтение (необязательно).
    mobile_bearer_token: str = ""
    # Токен 1С для /sync/*. Пока пуст — синк принимает API_BEARER_TOKEN, как раньше.
    sync_bearer_token: str = ""
    # Переходный режим: синк принимает и SYNC_BEARER_TOKEN, и API_BEARER_TOKEN.
    sync_accept_legacy_token: bool = False
    # Пересчёт кэша групп после синка: пауза (сек), чтобы пачки 1С собрать в один пересчёт.
    # 0 — пересчитывать сразу в запросе синка (старое поведение).
    catalog_rebuild_debounce_seconds: float = 5.0
    min_app_version: str = "1.0.1"
    min_app_version_ios: str = "1.0.1"
    min_app_version_android: str = "1.0.1"

    @field_validator(
        "api_bearer_token", "mobile_bearer_token", "sync_bearer_token", mode="before"
    )
    @classmethod
    def normalize_bearer_token(cls, value: object) -> str:
        if value is None:
            return ""
        text = str(value).strip()
        if len(text) >= 2 and text[0] == text[-1] and text[0] in {"'", '"'}:
            text = text[1:-1].strip()
        return text


settings = Settings()
