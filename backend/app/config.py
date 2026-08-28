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
        # Check explicit environment variables first
        candidate_keys = [
            "DATABASE_URL",
            "DATABASE_PRIVATE_URL",
            "DATABASE_PUBLIC_URL",
            "POSTGRES_URL",
            "POSTGRESQL_URL",
            "PGDATABASE_URL",
        ]
        resolved = None
        for k in candidate_keys:
            val = os.getenv(k)
            if val and not val.startswith("sqlite"):
                resolved = val
                break

        if not resolved and v and not v.startswith("sqlite"):
            resolved = v

        # Fallback: construct from standard PostgreSQL env vars injected by Railway/Docker
        if not resolved:
            pghost = os.getenv("PGHOST") or os.getenv("POSTGRES_HOST")
            pgdb = os.getenv("PGDATABASE") or os.getenv("POSTGRES_DB")
            if pghost and pgdb:
                pguser = os.getenv("PGUSER") or os.getenv("POSTGRES_USER", "postgres")
                pgpassword = os.getenv("PGPASSWORD") or os.getenv("POSTGRES_PASSWORD", "")
                pgport = os.getenv("PGPORT") or os.getenv("POSTGRES_PORT", "5432")
                auth = f"{pguser}:{pgpassword}@" if pgpassword else f"{pguser}@"
                resolved = f"postgresql://{auth}{pghost}:{pgport}/{pgdb}"

        if not resolved:
            return "sqlite:///./dinnerhome.db"

        # Railway provides 'postgres://', SQLAlchemy 2.0 requires 'postgresql://'
        resolved = resolved.strip()
        if resolved.startswith("postgres://"):
            resolved = resolved.replace("postgres://", "postgresql://", 1)

        return resolved

    @property
    def cors_origins_list(self) -> List[str]:
        if isinstance(self.CORS_ORIGINS, list):
            return self.CORS_ORIGINS
        if self.CORS_ORIGINS == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]

settings = Settings()
