import sys
import os

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.db.database import engine, Base
from app.db.models import LearningResource, Quiz, QuizQuestion, QuizAttempt
from sqlalchemy import text

def run_migration():
    print("[+] Starting database migration for Learning & Quiz system...")
    
    # 1. Create any missing tables (e.g. learning_resources, quizzes, quiz_questions, quiz_attempts)
    Base.metadata.create_all(bind=engine)
    print("  - Ensured all tables exist in Base.metadata")

    # 2. Add any missing columns to existing tables
    columns_to_add = [
        ("lessons", "summary", "TEXT NULL"),
        ("lessons", "video_url", "VARCHAR(500) NULL"),
        ("lessons", "pdf_url", "VARCHAR(500) NULL"),
        ("lessons", "doc_url", "VARCHAR(500) NULL"),
    ]

    with engine.connect() as conn:
        for table, col, col_def in columns_to_add:
            try:
                # Check if column exists
                check_query = text(f"""
                    SELECT COUNT(*) 
                    FROM INFORMATION_SCHEMA.COLUMNS 
                    WHERE TABLE_SCHEMA = DATABASE() 
                      AND TABLE_NAME = '{table}' 
                      AND COLUMN_NAME = '{col}'
                """)
                res = conn.execute(check_query).scalar()
                if res == 0:
                    conn.execute(text(f"ALTER TABLE `{table}` ADD COLUMN `{col}` {col_def}"))
                    conn.commit()
                    print(f"  + Added column `{table}`.`{col}`")
                else:
                    print(f"  - Column `{table}`.`{col}` already exists")
            except Exception as ex:
                print(f"  ! Column check/add for `{table}`.`{col}`: {ex}")

    print("[SUCCESS] Database migration completed successfully!")

if __name__ == "__main__":
    run_migration()
