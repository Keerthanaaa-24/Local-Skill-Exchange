import sys
import os

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend")))

from app.db.database import SessionLocal
from app.db.models import User, Skill, LearningPath, Lesson, Quiz, QuizAttempt
from app.services import learning_service, certificate_service
from app.schemas.learning import QuizSubmission, QuizSubmissionItem

def run_tests():
    db = SessionLocal()
    try:
        user = db.query(User).first()
        if not user:
            print("[ERROR] No user found in database.")
            return

        print(f"[TEST 1] Testing dynamic path retrieval for skill #1 (Python)...")
        path1 = learning_service.get_or_create_learning_path_for_skill(db, 1)
        assert path1 is not None and path1.id > 0
        lessons1 = db.query(Lesson).filter(Lesson.learning_path_id == path1.id).all()
        assert len(lessons1) > 0
        print(f"  Passed! Path ID: {path1.id}, Title: {path1.title}, Lessons: {len(lessons1)}")

        print(f"\n[TEST 2] Testing on-demand path generation for arbitrary catalog skill...")
        skill_sample = db.query(Skill).filter(Skill.id > 20).first()
        if skill_sample:
            path2 = learning_service.get_or_create_learning_path_for_skill(db, skill_sample.id)
            assert path2 is not None and path2.id > 0
            lessons2 = db.query(Lesson).filter(Lesson.learning_path_id == path2.id).all()
            print(f"  Passed! Auto-generated Path for '{skill_sample.name}': {path2.title} with {len(lessons2)} lessons and study resources!")

        print(f"\n[TEST 3] Testing dynamic user learning dashboard calculation...")
        dashboard = learning_service.get_user_learning_dashboard(db, user.id)
        assert dashboard is not None
        print(f"  Passed! Dashboard returned: {dashboard.total_enrolled_paths} enrolled paths, {dashboard.total_lessons_completed} lessons completed, streak: {dashboard.streak_days}d, quiz avg: {dashboard.quiz_average_score}%")

        print(f"\n[TEST 4] Testing path timed quiz fetch...")
        quiz = learning_service.get_quiz_for_path(db, path1.id)
        assert quiz is not None and len(quiz.questions) > 0
        print(f"  Passed! Quiz #{quiz.id}: '{quiz.title}' with {len(quiz.questions)} timed questions (time limit: {quiz.time_limit_minutes} min)")

        print(f"\n[TEST 5] Testing quiz answer submission & server grading...")
        sub_items = [
            QuizSubmissionItem(question_id=q.id, answer=q.correct_answer)
            for q in quiz.questions
        ]
        submission = QuizSubmission(answers=sub_items, duration_seconds=180)
        grade_res = learning_service.grade_quiz_submission(db, user, quiz.id, submission)
        assert grade_res.percentage == 100.0
        assert grade_res.passed is True
        print(f"  Passed! Result: Score {grade_res.marks_obtained}/{grade_res.maximum_marks} ({grade_res.percentage}%), Passed: {grade_res.passed}, XP: +{grade_res.xp_earned}")

        print(f"\n[TEST 6] Testing certificate verification...")
        cert = db.query(certificate_service.Certificate).first()
        if cert:
            verify_res = certificate_service.verify_certificate_code(db, cert.verification_code)
            assert verify_res["valid"] is True
            print(f"  Passed! Verified Certificate #{verify_res['certificate_number']} for '{verify_res['recipient_name']}'")

        print("\n[ALL LEARNING & ASSESSMENT TESTS PASSED!]")
    finally:
        db.close()

if __name__ == "__main__":
    run_tests()

