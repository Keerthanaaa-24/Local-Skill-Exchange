import os
import sys

# Ensure backend path is in sys.path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app.db.database import SessionLocal
from app.db.models import User

def audit_database_users():
    db = SessionLocal()
    try:
        users = db.query(User).all()
        print(f"Total Users in DB: {len(users)}")
        
        test_user_keywords = ["test", "demo", "e2e", "audit", "user two", "user_two", "fake", "mock", "sample", "directtest"]
        
        updated_count = 0
        real_users = []
        test_users = []

        for u in users:
            email_lower = (u.email or "").lower()
            name_lower = (u.name or "").lower()
            
            # Check if this user is a test user
            is_test = False
            
            # Specific check for legitimate real user: keerthanamr1307@gmail.com or other real accounts
            if email_lower in ["keerthanamr1307@gmail.com"]:
                is_test = False
            else:
                for kw in test_user_keywords:
                    if kw in email_lower or kw in name_lower:
                        is_test = True
                        break
            
            if u.is_test_user != is_test:
                u.is_test_user = is_test
                updated_count += 1
                
            if is_test:
                test_users.append(u)
            else:
                real_users.append(u)

        db.commit()
        print(f"Audit completed. Updated {updated_count} users.")
        print(f"Legitimate Real Users ({len(real_users)}):")
        for ru in real_users:
            print(f"  - ID: {ru.id}, Email: {ru.email}, Name: {ru.name}, is_test_user: {ru.is_test_user}")

        print(f"Test/Demo Users ({len(test_users)}):")
        for tu in test_users:
            print(f"  - ID: {tu.id}, Email: {tu.email}, Name: {tu.name}, is_test_user: {tu.is_test_user}")

    finally:
        db.close()

if __name__ == "__main__":
    audit_database_users()
