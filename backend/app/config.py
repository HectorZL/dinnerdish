import os
from typing import List, Union
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

    PORT: int = 8000
    HOST: str = "0.0.0.0"
    ENV: str = "production"

    # Database URL
    DATABASE_URL: str = "sqlite:///./dinnerhome.db"

    # JWT Settings
    JWT_SECRET_KEY: str = "dinnerhome-pos-secret-key-change-in-production-super-secure"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 30  # 30 days default

    # CORS
    CORS_ORIGINS: Union[str, List[str]] = "*"

    # Default Admin Seed
    ADMIN_USERNAME: str = "admin"
    ADMIN_PASSWORD: str = "admin123"
    ADMIN_NAME: str = "Administrador"

    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def assemble_db_connection(cls, v: str | None) -> str:
        if not v:
            return "sqlite:///./dinnerhome.db"
        # Railway provides 'postgres://', SQLAlchemy 2.0 requires 'postgresql://'
        if v.startswith("postgres://"):
            return v.replace("postgres://", "postgresql://", 1)
        return v

    @property
    def cors_origins_list(self) -> List[str]:
        if isinstance(self.CORS_ORIGINS, list):
            return self.CORS_ORIGINS
        if self.CORS_ORIGINS == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]

settings = Settings()
