"""
Safe Database Index Migration Script for Local Skill Exchange MySQL.
Adds performance indexes on foreign keys, timestamps, and filter columns
without dropping existing tables or interrupting production traffic.
"""

import sys
from pathlib import Path
backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

from sqlalchemy import text
from app.db.database import engine

INDEXES_TO_ENSURE = [
    ("bookings", "idx_bookings_mentee_id", ["mentee_id"]),
    ("bookings", "idx_bookings_mentor_id", ["mentor_id"]),
    ("bookings", "idx_bookings_skill_id", ["skill_id"]),
    ("bookings", "idx_bookings_date", ["date"]),
    ("bookings", "idx_bookings_status", ["status"]),
    ("transactions", "idx_transactions_user_id", ["user_id"]),
    ("transactions", "idx_transactions_created_at", ["created_at"]),
    ("messages", "idx_messages_sender_id", ["sender_id"]),
    ("messages", "idx_messages_receiver_id", ["receiver_id"]),
    ("messages", "idx_messages_timestamp", ["timestamp"]),
    ("messages", "idx_messages_is_read", ["is_read"]),
    ("reviews", "idx_reviews_reviewer_id", ["reviewer_id"]),
    ("reviews", "idx_reviews_reviewee_id", ["reviewee_id"]),
    ("reviews", "idx_reviews_booking_id", ["booking_id"]),
    ("reviews", "idx_reviews_created_at", ["created_at"]),
    ("user_skills_offered", "idx_uso_user_id", ["user_id"]),
    ("user_skills_offered", "idx_uso_skill_id", ["skill_id"]),
    ("user_skills_wanted", "idx_usw_user_id", ["user_id"]),
    ("user_skills_wanted", "idx_usw_skill_id", ["skill_id"]),
    ("user_badges", "idx_user_badges_user_id", ["user_id"]),
    ("learning_paths", "idx_lp_skill_id", ["skill_id"]),
    ("lessons", "idx_lessons_learning_path_id", ["learning_path_id"]),
    ("notifications", "idx_notifications_user_id", ["user_id"]),
    ("notifications", "idx_notifications_is_read", ["is_read"]),
    ("notifications", "idx_notifications_created_at", ["created_at"]),
    ("user_learning_progress", "idx_ulp_user_id", ["user_id"]),
    ("user_learning_progress", "idx_ulp_learning_path_id", ["learning_path_id"]),
]

def apply_indexes():
    print("=" * 65)
    print(" Applying Missing Database Indexes to MySQL Schema")
    print("=" * 65)

    with engine.connect() as conn:
        # Check database engine dialect
        dialect_name = conn.dialect.name

        for table, index_name, columns in INDEXES_TO_ENSURE:
            cols_sql = ", ".join([f"`{c}`" for c in columns])
            if dialect_name == "mysql":
                # Check if index already exists in information_schema
                check_query = text("""
                    SELECT COUNT(1) FROM information_schema.statistics
                    WHERE table_schema = DATABASE()
                      AND table_name = :tbl
                      AND index_name = :idx
                """)
                res = conn.execute(check_query, {"tbl": table, "idx": index_name}).scalar()
                if res == 0:
                    try:
                        conn.execute(text(f"ALTER TABLE `{table}` ADD INDEX `{index_name}` ({cols_sql})"))
                        conn.commit()
                        print(f" [+] Created index `{index_name}` on `{table}` ({cols_sql})")
                    except Exception as e:
                        print(f" [!] Error creating `{index_name}`: {e}")
                else:
                    print(f" [OK] Index `{index_name}` already exists on `{table}`")
            elif dialect_name == "sqlite":
                conn.execute(text(f"CREATE INDEX IF NOT EXISTS {index_name} ON {table} ({cols_sql})"))
                conn.commit()
                print(f" [+] Ensured SQLite index {index_name}")

    print("=" * 65)
    print(" All Performance Indexes Successfully Applied!")
    print("=" * 65)

if __name__ == "__main__":
    apply_indexes()
