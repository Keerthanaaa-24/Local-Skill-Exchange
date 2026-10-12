import os, sys
# Ensure project root is in PYTHONPATH for relative imports
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
if project_root not in sys.path:
    sys.path.append(project_root)

# Load environment variables from .env (if present)
from pathlib import Path
env_path = Path(project_root) / '.env'
if env_path.is_file():
    from dotenv import load_dotenv
    load_dotenv(dotenv_path=env_path)

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from backend.app.core.config import Settings
# Re-instantiate settings after loading .env
settings = Settings()
from backend.app.db import models
from backend.app.db.database import Base

engine = create_engine(settings.DATABASE_URL, echo=False, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_or_create_learning_path(session, skill):
    # Check if a learning path for this skill already exists (by title)
    path_title = f"Introduction to {skill.name}"
    existing = session.execute(
        text("SELECT id FROM learning_paths WHERE title = :title"),
        {"title": path_title}
    ).fetchone()
    if existing:
        path_id = existing.id
        print(f"LearningPath already exists: {path_title} (id={path_id})")
        return path_id
    # Create new learning path
    session.execute(
        text(
            "INSERT INTO learning_paths (skill_id, title, description, estimated_minutes) "
            "VALUES (:skill_id, :title, :description, :estimated_minutes)"
        ),
        {
            "skill_id": skill.id,
            "title": path_title,
            "description": f"A beginner-friendly learning path that introduces the core concepts of {skill.name}.",
            "estimated_minutes": 120,
        },
    )
    session.commit()
    path_id = session.execute(
        text("SELECT id FROM learning_paths WHERE title = :title"),
        {"title": path_title},
    ).fetchone().id
    print(f"Created LearningPath: {path_title} (id={path_id})")
    return path_id

def create_lessons_if_missing(session, path_id, skill_name):
    # Define 5 lessons with meaningful content
    lesson_titles = [
        f"What is {skill_name}?",
        f"Core Principles of {skill_name}",
        f"Practical Applications of {skill_name}",
        f"Advanced Topics in {skill_name}",
        f"Summary and Next Steps for {skill_name}",
    ]
    created = 0
    for order, title in enumerate(lesson_titles, start=1):
        existing = session.execute(
            text("SELECT id FROM lessons WHERE learning_path_id = :path_id AND title = :title"),
            {"path_id": path_id, "title": title},
        ).fetchone()
        if existing:
            continue
        content = f"This lesson covers {title.lower()}. Detailed explanation and examples go here."
        session.execute(
            text(
                "INSERT INTO lessons (learning_path_id, title, content, `order`, estimated_minutes) "
                "VALUES (:path_id, :title, :content, :order, :minutes)"
            ),
            {
                "path_id": path_id,
                "title": title,
                "content": content,
                "order": order,
                "minutes": 20,
            },
        )
        created += 1
    session.commit()
    print(f"Created {created} new lessons for path_id={path_id}")

def main():
    # Ensure tables exist (in case DB was empty)
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as session:
        # Pick first skill
        # Retrieve first skill record
        skill_row = session.execute(text("SELECT id, name FROM skills LIMIT 1")).fetchone()
        if not skill_row:
            print("ERROR: No Skill records found in the database.")
            return
        # Convert Row to simple object
        class SimpleSkill:
            pass
        skill = SimpleSkill()
        skill.id = skill_row.id
        skill.name = skill_row.name
        path_id = get_or_create_learning_path(session, skill)
        create_lessons_if_missing(session, path_id, skill.name)

if __name__ == "__main__":
    main()
