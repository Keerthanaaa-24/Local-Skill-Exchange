from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List, Dict

from ..deps import SessionDep, CurrentUser
from ...db.models import (
    Skill,
    LearningPath,
    Lesson,
    UserLearningProgress,
    PracticeQuestion,
    PracticeAttempt,
    Quiz,
    QuizQuestion,
    QuizAttempt,
)
from ...schemas.learning import (
    LearningPathOut,
    LessonOut,
    UserLearningProgressOut,
    StartLearningResponse,
    LessonCompleteResponse,
    PracticeQuestionOut,
    PracticeSubmission,
    PracticeResultOut,
    QuizOut,
    QuizSubmission,
    QuizResultOut,
    QuizAttemptOut,
    LearningDashboardOut,
)
from ...services import certificate_service, gamification_service, learning_service, notification_service

router = APIRouter()

def _parse_completed(completed_str: str) -> list[int]:
    if not completed_str:
        return []
    return [int(i) for i in completed_str.split(",") if i]

def _serialize_completed(ids: list[int]) -> str:
    return ",".join(str(i) for i in sorted(set(ids)))

@router.get("/dashboard/me", response_model=LearningDashboardOut)
def get_user_dashboard(db: SessionDep, user: CurrentUser):
    """
    Returns real-time learning metrics, active enrolled skills, lesson progress,
    quiz score averages, streak, and recent quiz attempts.
    """
    return learning_service.get_user_learning_dashboard(db, user.id)

@router.get("/paths", response_model=list[LearningPathOut])
def list_learning_paths(db: SessionDep, _: CurrentUser):
    return db.query(LearningPath).all()

@router.get("/paths/skill/{skill_id}", response_model=LearningPathOut)
def get_or_create_path_by_skill(skill_id: int, db: SessionDep, _: CurrentUser):
    """
    Fetches the learning path for a skill, or automatically creates a curated,
    verified multi-module path with study resources, practice, and a final quiz.
    """
    return learning_service.get_or_create_learning_path_for_skill(db, skill_id)

@router.get("/paths/{path_id}", response_model=LearningPathOut)
def get_learning_path(path_id: int, db: SessionDep, _: CurrentUser):
    path = db.query(LearningPath).filter(LearningPath.id == path_id).first()
    if not path:
        raise HTTPException(status_code=404, detail="Learning path not found")
    return path

@router.get("/paths/{path_id}/lessons", response_model=list[LessonOut])
def list_lessons(path_id: int, db: SessionDep, user: CurrentUser):
    path = db.query(LearningPath).filter(LearningPath.id == path_id).first()
    if not path:
        raise HTTPException(status_code=404, detail="Learning path not found")
    skill = db.query(Skill).filter(Skill.id == path.skill_id).first()
    if skill:
        learning_service._ensure_path_resources_and_questions(db, path, skill)
    lessons = (
        db.query(Lesson)
        .filter(Lesson.learning_path_id == path_id)
        .order_by(Lesson.order)
        .all()
    )
    return lessons

@router.post("/paths/{path_id}/start", response_model=StartLearningResponse)
def start_learning(path_id: int, db: SessionDep, user: CurrentUser):
    path = db.query(LearningPath).filter(LearningPath.id == path_id).first()
    if not path:
        raise HTTPException(status_code=404, detail="Learning path not found")
    progress = (
        db.query(UserLearningProgress)
        .filter(UserLearningProgress.user_id == user.id, UserLearningProgress.learning_path_id == path_id)
        .first()
    )
    if not progress:
        progress = UserLearningProgress(
            user_id=user.id,
            learning_path_id=path_id,
            started_at=datetime.utcnow(),
            completed_lessons="",
        )
        db.add(progress)
        db.commit()
        db.refresh(progress)
        # Award +10 XP for starting path (idempotent)
        gamification_service.award_xp_idempotent(
            db, user.id, 10, f"start_path:{path_id}", f"Enrolled in {path.title}"
        )
        gamification_service.check_and_award_achievements(db, user.id)
    return StartLearningResponse(
        progress=UserLearningProgressOut.model_validate(progress),
        message="Learning started",
    )

@router.get("/progress", response_model=list[UserLearningProgressOut])
def list_user_progress(db: SessionDep, user: CurrentUser):
    return db.query(UserLearningProgress).filter(UserLearningProgress.user_id == user.id).all()

@router.get("/progress/{path_id}", response_model=UserLearningProgressOut)
def get_user_progress(path_id: int, db: SessionDep, user: CurrentUser):
    progress = (
        db.query(UserLearningProgress)
        .filter(UserLearningProgress.user_id == user.id, UserLearningProgress.learning_path_id == path_id)
        .first()
    )
    if not progress:
        raise HTTPException(status_code=404, detail="Progress not found")
    return progress

@router.post("/lessons/{lesson_id}/complete", response_model=LessonCompleteResponse)
def complete_lesson(lesson_id: int, db: SessionDep, user: CurrentUser):
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")
    progress = (
        db.query(UserLearningProgress)
        .filter(
            UserLearningProgress.user_id == user.id,
            UserLearningProgress.learning_path_id == lesson.learning_path_id,
        )
        .first()
    )
    if not progress:
        raise HTTPException(status_code=400, detail="Learning not started for this path")
    completed_ids = _parse_completed(progress.completed_lessons)
    if lesson.id not in completed_ids:
        completed_ids.append(lesson.id)
        progress.completed_lessons = _serialize_completed(completed_ids)
        total = db.query(Lesson).filter(Lesson.learning_path_id == lesson.learning_path_id).count()
        if len(completed_ids) >= total and progress.completed_at is None:
            progress.completed_at = datetime.utcnow()
        db.commit()
        db.refresh(progress)

        # Award +20 XP for lesson completion (idempotent)
        gamification_service.award_xp_idempotent(
            db, user.id, 20, f"complete_lesson:{lesson.id}", f"Completed lesson: {lesson.title}"
        )

        # If completed entire path, award +100 XP & create course completed notification
        if len(completed_ids) >= total:
            gamification_service.award_xp_idempotent(
                db, user.id, 100, f"complete_path:{lesson.learning_path_id}", f"Completed learning path #{lesson.learning_path_id}"
            )
            path = db.query(LearningPath).filter(LearningPath.id == lesson.learning_path_id).first()
            path_title = path.title if path else "Skill Course"
            notification_service.create_notification(
                db=db,
                user_id=user.id,
                title="Course Completed!",
                message=f"Congratulations! You completed {path_title}.",
                notification_type="COURSE_COMPLETED",
                target_id=lesson.learning_path_id,
            )
            # Automatic Certificate Issuance on completion
            try:
                certificate_service.verify_and_issue_certificate(db, user, lesson.learning_path_id)
            except Exception:
                pass

        gamification_service.check_and_award_achievements(db, user.id)
    return LessonCompleteResponse(
        progress=UserLearningProgressOut.model_validate(progress),
        message="Lesson marked complete",
    )

@router.get("/lessons/{lesson_id}/practice", response_model=List[PracticeQuestionOut])
def get_practice_questions(lesson_id: int, db: SessionDep, user: CurrentUser):
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")
    questions = db.query(PracticeQuestion).filter(PracticeQuestion.lesson_id == lesson_id).all()
    if not questions:
        path = db.query(LearningPath).filter(LearningPath.id == lesson.learning_path_id).first()
        if path:
            skill = db.query(Skill).filter(Skill.id == path.skill_id).first()
            if skill:
                learning_service._ensure_path_resources_and_questions(db, path, skill)
                questions = db.query(PracticeQuestion).filter(PracticeQuestion.lesson_id == lesson_id).all()
    return questions

@router.post("/lessons/{lesson_id}/practice/submit", response_model=PracticeResultOut)
def submit_practice(lesson_id: int, submission: PracticeSubmission, db: SessionDep, user: CurrentUser):
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")
    # Load questions for lesson
    questions = db.query(PracticeQuestion).filter(PracticeQuestion.lesson_id == lesson_id).all()
    if not questions:
        raise HTTPException(status_code=400, detail="No practice questions for this lesson")
    # Map submissions by question_id
    answer_map = {}
    for a in submission.answers:
        q_id = int(a.question_id if hasattr(a, "question_id") else a["question_id"])
        ans_val = a.answer if hasattr(a, "answer") else a["answer"]
        answer_map[q_id] = ans_val
    total = len(questions)
    correct = 0
    feedback = []
    for q in questions:
        user_answer = answer_map.get(q.id)
        is_correct = user_answer == q.correct_answer
        if is_correct:
            correct += 1
        feedback.append({"question_id": q.id, "correct": is_correct, "explanation": q.explanation})
    percentage = (correct / total) * 100 if total else 0
    passed = percentage >= 70
    # Record attempt
    attempt = PracticeAttempt(
        user_id=user.id,
        lesson_id=lesson_id,
        score=int(percentage),
        total_questions=total,
        correct_answers=correct,
        completed_at=datetime.utcnow(),
    )
    db.add(attempt)
    db.commit()

    if passed:
        gamification_service.award_xp_idempotent(
            db, user.id, 30, f"pass_practice:{lesson_id}", f"Passed practice quiz for lesson #{lesson_id}"
        )
        gamification_service.check_and_award_achievements(db, user.id)

    notification_service.create_notification(
        db=db,
        user_id=user.id,
        title="Quiz Completed",
        message=f"{lesson.title} quiz completed — {int(percentage)}%.",
        notification_type="QUIZ_COMPLETED",
        target_id=lesson.id,
    )

    return PracticeResultOut(
        lesson_id=lesson_id,
        total_questions=total,
        correct_answers=correct,
        incorrect_answers=total - correct,
        percentage=percentage,
        passed=passed,
        feedback=feedback,
    )

@router.get("/lessons/{lesson_id}/practice/history", response_model=List[PracticeResultOut])
def get_practice_history(lesson_id: int, db: SessionDep, user: CurrentUser):
    attempts = (
        db.query(PracticeAttempt)
        .filter(PracticeAttempt.user_id == user.id, PracticeAttempt.lesson_id == lesson_id)
        .order_by(PracticeAttempt.completed_at.desc())
        .all()
    )
    results = []
    for a in attempts:
        results.append(
            PracticeResultOut(
                lesson_id=lesson_id,
                total_questions=a.total_questions,
                correct_answers=a.correct_answers,
                incorrect_answers=a.total_questions - a.correct_answers,
                percentage=a.score,
                passed=a.score >= 70,
                feedback=[],
            )
        )
    return results

# ================= Timed Quizzes & Assessments =================

@router.get("/paths/{path_id}/quiz", response_model=QuizOut)
def get_learning_path_quiz(path_id: int, db: SessionDep, user: CurrentUser):
    """
    Fetches the timed quiz for a learning path.
    """
    quiz = learning_service.get_quiz_for_path(db, path_id)
    if not quiz:
        raise HTTPException(status_code=404, detail="No quiz available for this learning path")
    return quiz

@router.post("/quizzes/{quiz_id}/submit", response_model=QuizResultOut)
def submit_quiz_answers(
    quiz_id: int, submission: QuizSubmission, db: SessionDep, user: CurrentUser
):
    """
    Grades the timed quiz submission, records the attempt, calculates score, and awards XP.
    """
    return learning_service.grade_quiz_submission(db, user, quiz_id, submission)

@router.get("/quizzes/{quiz_id}/attempts", response_model=List[QuizAttemptOut])
def get_quiz_attempts(quiz_id: int, db: SessionDep, user: CurrentUser):
    """
    Retrieves all past attempts of the current user for the given quiz.
    """
    attempts = (
        db.query(QuizAttempt)
        .filter(QuizAttempt.quiz_id == quiz_id, QuizAttempt.user_id == user.id)
        .order_by(QuizAttempt.completed_at.desc())
        .all()
    )
    return attempts
