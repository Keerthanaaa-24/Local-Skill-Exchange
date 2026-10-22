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

class Settings(BaseSettings):
    PROJECT_NAME: str = "Local Skill Exchange API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    
    SECRET_KEY: str = os.getenv("SECRET_KEY", "super-secret-key-change-in-production")
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

