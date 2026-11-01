from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from typing import List
import os

_backend_env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), ".env")

class Settings(BaseSettings):
    PROJECT_NAME: str = "MeetMind AI — Intelligent Meeting Assistant"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    SECRET_KEY: str = "meetmind-dev-secret-key-super-secure-2026"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 # 24 hours

    DATABASE_URL: str = "sqlite:///./meetmind.db"
    STORAGE_DIR: str = "./storage"
    MAX_UPLOAD_SIZE_MB: int = 100

    OPENAI_API_KEY: str = ""
    GEMINI_API_KEY: str = ""
    OLLAMA_API_KEY: str = ""
    OLLAMA_MODEL: str = "glm-5.3-flash"
    OLLAMA_BASE_URL: str = "https://ollama.com"
    WHISPER_MODEL: str = "base"

    BACKEND_CORS_ORIGINS: List[str] = [
        "https://meetmind-ai-74519.web.app",
        "https://meetmind-ai-74519.firebaseapp.com",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:3000",
        "*"
    ]

    model_config = ConfigDict(
        env_file=(_backend_env_path, ".env"),
        case_sensitive=True,
        extra="allow"
    )

settings = Settings()
