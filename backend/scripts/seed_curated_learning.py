import sys
import os

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.db.database import SessionLocal
from app.db.models import (
    Skill,
    LearningPath,
    Lesson,
    LearningResource,
    PracticeQuestion,
    Quiz,
    QuizQuestion,
)
from app.services.learning_service import get_or_create_learning_path_for_skill

def seed_curated_flagship_paths():
    db = SessionLocal()
    try:
        print("[+] Seeding curated learning paths with verified study materials...")

        flagship_skills = [
            "Python",
            "Flutter",
            "JavaScript",
            "React",
            "UI/UX Design",
            "Graphic Design",
            "Guitar",
            "Photography",
            "French",
            "Machine Learning",
            "Data Science",
            "Cybersecurity",
            "Digital Marketing",
            "Public Speaking",
            "Cooking",
        ]

        count_seeded = 0
        for skill_query in flagship_skills:
            skill = (
                db.query(Skill)
                .filter(Skill.name.ilike(f"%{skill_query}%"))
                .first()
            )
            if not skill:
                # Create the skill if not present
                skill = Skill(name=skill_query, category="General")
                db.add(skill)
                db.commit()
                db.refresh(skill)

            path = get_or_create_learning_path_for_skill(db, skill.id)
            count_seeded += 1
            print(f"  - Seeded/verified path for: {skill.name} (Path #{path.id})")

        print(f"\n[SUCCESS] Successfully seeded/verified {count_seeded} flagship learning paths!")
    except Exception as e:
        print(f"[ERROR] Error seeding learning paths: {e}")
        db.rollback()
        raise e
    finally:
        db.close()

if __name__ == "__main__":
    seed_curated_flagship_paths()
