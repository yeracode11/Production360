from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = (
        "postgresql+asyncpg://production360:production360@localhost:5432/production360"
    )
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    cors_origins: str = "*"


settings = Settings()
