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
    api_bearer_token: str = ""
    min_app_version: str = "1.0.1"
    min_app_version_ios: str = "1.0.1"
    min_app_version_android: str = "1.0.1"

    @field_validator("api_bearer_token", mode="before")
    @classmethod
    def normalize_bearer_token(cls, value: object) -> str:
        if value is None:
            return ""
        text = str(value).strip()
        if len(text) >= 2 and text[0] == text[-1] and text[0] in {"'", '"'}:
            text = text[1:-1].strip()
        return text


settings = Settings()
