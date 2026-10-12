import os
from pathlib import Path
from dotenv import load_dotenv
from pydantic_settings import BaseSettings
# Load .env from the project root (three levels up from backend/app/core/config.py)
project_root = Path(__file__).resolve().parents[3]
load_dotenv(project_root / '.env', override=True)

class Settings(BaseSettings):
    PROJECT_NAME: str = "Local Skill Exchange API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    SECRET_KEY: str = os.getenv("SECRET_KEY", "super-secret-key-change-in-production")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 days
    
    # Database
    # Use SQLite for development to run immediately without MySQL setup
    # To use MySQL, change this to: mysql+pymysql://user:password@localhost:3306/db_name
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./sql_app.db")
    
    class Config:
        case_sensitive = True

settings = Settings()
