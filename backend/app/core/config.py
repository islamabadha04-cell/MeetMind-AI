from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "Smart Noter AI — Meeting Assistant"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    SECRET_KEY: str = "smart-noter-dev-secret-key-super-secure-2027"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 # 24 hours

    DATABASE_URL: str = "sqlite:///./smart_noter.db"
    STORAGE_DIR: str = "./storage"
    MAX_UPLOAD_SIZE_MB: int = 100

    OPENAI_API_KEY: str = ""
    GEMINI_API_KEY: str = ""
    WHISPER_MODEL: str = "base"

    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://192.168.140.112:8080",
        "http://localhost:3000",
        "*"
    ]

    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
