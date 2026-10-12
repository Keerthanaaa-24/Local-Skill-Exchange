import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from sqlalchemy import text
from app.db.database import engine

def migrate():
    print("Running migration: Add is_test_user to users table...")
    with engine.connect() as conn:
        result = conn.execute(text("""
            SELECT COUNT(*) 
            FROM information_schema.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'users' 
              AND COLUMN_NAME = 'is_test_user'
        """))
        exists = result.scalar() > 0
        if not exists:
            print("Adding column 'is_test_user' to 'users' table...")
            conn.execute(text("ALTER TABLE users ADD COLUMN is_test_user BOOLEAN NOT NULL DEFAULT FALSE"))
            conn.execute(text("CREATE INDEX ix_users_is_test_user ON users (is_test_user)"))
            conn.commit()
            print("Successfully added is_test_user column and index.")
        else:
            print("Column 'is_test_user' already exists.")

if __name__ == "__main__":
    migrate()
