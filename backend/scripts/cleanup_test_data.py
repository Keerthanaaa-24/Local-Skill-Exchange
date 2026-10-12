import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.db.database import SessionLocal
from app.db.models import (
    User,
    Skill,
    Booking,
    Review,
    Certificate,
    UserLearningProgress,
    UserSkillOffered,
    UserSkillWanted,
    Message,
    Transaction,
    Notification,
    UserReport,
    UserBlock,
    UserAchievement,
    UserXpLog,
    PracticeAttempt,
    QuizAttempt,
)

def cleanup_test_data(mark_only=False):
    db = SessionLocal()
    try:
        print("==================================================")
        print("LOCAL SKILL EXCHANGE - TEST DATA CLEANUP & AUDIT")
        print("==================================================")

        all_users = db.query(User).all()
        print(f"Total existing users: {len(all_users)}")

        test_user_ids = []
        real_user_ids = []

        for u in all_users:
            email_lower = (u.email or "").strip().lower()
            name_lower = (u.name or "").strip().lower()

            # Identify real user vs test accounts
            is_test = (
                email_lower.endswith("@example.com")
                or email_lower.endswith("@test.com")
                or email_lower.startswith(("test_", "audit_user_", "e2e_test_", "phase_o_user_", "aicoach_"))
                or "test" in name_lower
                or "auditor" in name_lower
                or "tester" in name_lower
            )

            # Preserve real user Keerthana
            if "keerthana" in email_lower or "keerthana" in name_lower:
                is_test = False

            if is_test:
                u.is_test_user = True
                test_user_ids.append(u.id)
            else:
                u.is_test_user = False
                real_user_ids.append(u.id)

        db.commit()

        print(f"Marked {len(test_user_ids)} accounts as test users (is_test_user=True).")
        print(f"Identified {len(real_user_ids)} real user accounts (is_test_user=False).")

        total_skills = db.query(Skill).count()
        print(f"Total skills preserved: {total_skills}")

        # Summary of real vs test
        for u in db.query(User).filter(User.is_test_user == False).all():
            print(f"  [REAL USER] ID: {u.id}, Name: {u.name}, Email: {u.email}")

        print("Cleanup and classification completed successfully!")
    finally:
        db.close()

if __name__ == "__main__":
    cleanup_test_data()
