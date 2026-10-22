import os
from pathlib import Path
from dotenv import load_dotenv
from pydantic_settings import BaseSettings

# Load .env safely from candidate locations without throwing index errors
_current_file = Path(__file__).resolve()
_candidate_paths = [
    Path.cwd() / ".env",
    _current_file.parents[2] / ".env" if len(_current_file.parents) > 2 else None,
    _current_file.parents[3] / ".env" if len(_current_file.parents) > 3 else None,
]

for _env_path in _candidate_paths:
    if _env_path and _env_path.is_file():
        # Do not override existing system/cloud environment variables
        load_dotenv(_env_path, override=False)
        break

def _resolve_database_url() -> str:
    raw_url = os.getenv("DATABASE_URL") or os.getenv("MYSQL_URL") or "sqlite:///./sql_app.db"
    # Normalize standard mysql:// URI to mysql+pymysql:// for SQLAlchemy 2.0 compatibility
    if raw_url.startswith("mysql://"):
        raw_url = raw_url.replace("mysql://", "mysql+pymysql://", 1)
    return raw_url

KNOWN_INSECURE_KEYS = {
    "super-secret-key-change-in-production",
    "secret",
    "secretkey",
    "changeme",
    "admin",
    "password",
    "development",
    "test",
    "12345678",
    "1234567890",
}

def _resolve_secret_key() -> str:
    env = os.getenv("ENVIRONMENT", "development").strip().lower()
    raw_key = os.getenv("SECRET_KEY", "").strip()
    if not raw_key:
        if env == "production":
            raise RuntimeError(
                "CRITICAL SECURITY CONFIGURATION ERROR: SECRET_KEY environment variable "
                "must be explicitly set when ENVIRONMENT is 'production'."
            )
        return "super-secret-key-change-in-production"

    if env == "production":
        lower_key = raw_key.lower()
        if lower_key in KNOWN_INSECURE_KEYS or "change-in-production" in lower_key:
            raise RuntimeError(
                "CRITICAL SECURITY CONFIGURATION ERROR: The provided SECRET_KEY is a known "
                "insecure default and cannot be used in production. "
                "Generate a cryptographically secure key (e.g. openssl rand -hex 32)."
            )
        if len(raw_key) < 32:
            raise RuntimeError(
                "CRITICAL SECURITY CONFIGURATION ERROR: SECRET_KEY is too weak for production. "
                f"Minimum required length is 32 characters (current: {len(raw_key)} characters)."
            )
    return raw_key

class Settings(BaseSettings):
    PROJECT_NAME: str = "Local Skill Exchange API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    
    SECRET_KEY: str = _resolve_secret_key()
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 days
    
    # Database
    DATABASE_URL: str = _resolve_database_url()
    
    # CORS Configuration
    CORS_ORIGINS: str = os.getenv("CORS_ORIGINS", "*")
    
    # Google OAuth
    GOOGLE_CLIENT_ID: str = os.getenv("GOOGLE_CLIENT_ID", "")
    
    class Config:
        case_sensitive = True

settings = Settings()

