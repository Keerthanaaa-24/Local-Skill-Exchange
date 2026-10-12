import os
import sys
from pathlib import Path
from dotenv import load_dotenv

project_root = Path(__file__).resolve().parents[2]
load_dotenv(project_root / '.env', override=True)

backend_path = os.path.join(project_root, 'backend')
if backend_path not in sys.path:
    sys.path.append(backend_path)

from app.db.database import SessionLocal
from app.db.models import Lesson, PracticeQuestion, LearningPath, Skill
from app.services.course_catalog_data import get_curated_or_generated_course

def seed_practice_questions():
    """
    Seeds and enriches practice questions for all lessons in the database using
    topic-specific, domain-grounded questions from course_catalog_data.
    Completely removes and prevents generic placeholder questions.
    """
    db = SessionLocal()
    try:
        lessons = db.query(Lesson).all()
        count = 0
        for lesson in lessons:
            path = db.query(LearningPath).filter(LearningPath.id == lesson.learning_path_id).first()
            skill = db.query(Skill).filter(Skill.id == path.skill_id).first() if path else None
            
            skill_name = skill.name if skill else "General Skill"
            category = skill.category if skill else "General"
            
            course_data = get_curated_or_generated_course(skill_name, category)
            lesson_templates = course_data.get("lessons", [])
            
            # Find matching template by order or title
            tmpl = next((t for t in lesson_templates if t.get("order") == lesson.order), None)
            if not tmpl and lesson_templates:
                tmpl = lesson_templates[0]

            existing_pqs = db.query(PracticeQuestion).filter(PracticeQuestion.lesson_id == lesson.id).all()
            
            # Remove any placeholder questions
            has_placeholder = any(
                any(opt in ["Option A", "Option B", "Statement 1", "Example X"] for opt in (pq.options or []))
                or "primary purpose of this lesson" in pq.question.lower()
                for pq in existing_pqs
            )
            if has_placeholder:
                for pq in existing_pqs:
                    db.delete(pq)
                db.flush()
                existing_pqs = []

            if len(existing_pqs) == 0 and tmpl and tmpl.get("questions"):
                for q in tmpl["questions"]:
                    new_q = PracticeQuestion(
                        lesson_id=lesson.id,
                        question=q["question"],
                        question_type="mcq",
                        options=q["options"],
                        correct_answer=q["correct_answer"],
                        explanation=q.get("explanation", ""),
                    )
                    db.add(new_q)
                    count += 1
                db.commit()

        print(f"[SUCCESS] Seeded/verified topic-specific practice questions across {len(lessons)} lessons ({count} questions inserted).")
    except Exception as e:
        db.rollback()
        print(f"[ERROR] Error during practice seeding: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed_practice_questions()
