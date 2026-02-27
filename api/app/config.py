from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List, Optional
import os

class Settings(BaseSettings):
    """
    Project settings and environment variables.
    Pydantic handles automatic validation and environment variable loading.
    """
    # API Metadata
    PROJECT_NAME: str = "Synapse"
    VERSION: str = "1.0.0"
    DEBUG: bool = os.getenv("DEBUG", "False").lower() == "true"

    # Database URLs
    # Priority: SYNC_DATABASE_URL (Cloud Run/Celery) -> DATABASE_URL -> local fallback
    DATABASE_URL: str = "postgresql+asyncpg://synapse:synapse123@localhost:5432/synapse_db"
    SYNC_DATABASE_URL: Optional[str] = None

    @property
    def ASYNC_DATABASE_URL(self) -> str:
        """Returns the async version of the database URL."""
        return self.DATABASE_URL

    @property
    def SYNC_DATABASE_URL_READY(self) -> str:
        """Returns a sync-ready URL (replacing asyncpg with psycopg2)."""
        raw = self.SYNC_DATABASE_URL or self.DATABASE_URL
        return raw.replace("postgresql+asyncpg://", "postgresql://")

    # Redis (Broker & Cache)
    REDIS_URL: str = "redis://localhost:6379/0"

    # Security
    JWT_SECRET_KEY: str = "your-secret-key-change-in-production-PLEASE!"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # CORS
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost",
        "https://synapse-frontend-256447952073.us-central1.run.app",
    ]
    EXTRA_CORS_ORIGINS: Optional[str] = None

    @property
    def ALL_ORIGINS(self) -> List[str]:
        """Combines default origins with extra ones from env."""
        origins = list(self.ALLOWED_ORIGINS)
        if self.EXTRA_CORS_ORIGINS:
            origins.extend([o.strip() for o in self.EXTRA_CORS_ORIGINS.split(",") if o.strip()])
        return origins

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True
    )

settings = Settings()
