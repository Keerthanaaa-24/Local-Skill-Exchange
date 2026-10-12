import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.app.db.database import engine
from sqlalchemy import text

def run_migration():
    print("Running migration on MySQL database for notifications table...")
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE notifications ADD COLUMN type VARCHAR(50) DEFAULT 'general';"))
            print("Added column 'type' to notifications.")
        except Exception as e:
            print(f"Column 'type' notice: {e}")

        try:
            conn.execute(text("ALTER TABLE notifications ADD COLUMN target_id INT NULL;"))
            print("Added column 'target_id' to notifications.")
        except Exception as e:
            print(f"Column 'target_id' notice: {e}")

        conn.commit()
    print("Migration completed successfully.")

if __name__ == "__main__":
    run_migration()
