import urllib.parse
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from ..db.models import (
    Skill,
    LearningPath,
    Lesson,
    LearningResource,
    PracticeQuestion,
    Quiz,
    QuizQuestion,
    QuizAttempt,
    UserLearningProgress,
    Certificate,
    User,
)
from ..schemas.learning import (
    QuizSubmission,
    QuizResultOut,
    QuizFeedbackItem,
    QuizAttemptOut,
    LearningDashboardOut,
    LearningDashboardSkill,
)
from . import gamification_service

def _parse_completed(completed_str: str) -> list[int]:
    if not completed_str:
        return []
    return [int(i) for i in completed_str.split(",") if i.strip()]

from .course_catalog_data import get_curated_or_generated_course

def _ensure_path_resources_and_questions(db: Session, path: LearningPath, skill: Skill):
    course_data = get_curated_or_generated_course(skill.name, skill.category or "General")
    lesson_templates = course_data.get("lessons", [])
    lessons = db.query(Lesson).filter(Lesson.learning_path_id == path.id).order_by(Lesson.order).all()

    for i, lesson in enumerate(lessons):
        tmpl = lesson_templates[i] if i < len(lesson_templates) else (lesson_templates[0] if lesson_templates else None)
        if not tmpl:
            continue

        # Check and populate resources if empty
        res_count = db.query(LearningResource).filter(LearningResource.lesson_id == lesson.id).count()
        if res_count == 0 and tmpl.get("resources"):
            for res in tmpl["resources"]:
                resource = LearningResource(
                    lesson_id=lesson.id,
                    resource_type=res.get("type", "DOCS"),
                    title=res.get("title", f"{skill.name} Resource"),
                    url=res.get("url", "https://en.wikipedia.org"),
                    source=res.get("source", "Web"),
                    duration_minutes=res.get("duration", 15),
                    is_primary=res.get("is_primary", False),
                )
                db.add(resource)

        # Check and replace placeholder practice questions
        pqs = db.query(PracticeQuestion).filter(PracticeQuestion.lesson_id == lesson.id).all()
        has_placeholder = any(
            any(opt in ["Option A", "Option B", "Statement 1", "Example X"] for opt in (pq.options or []))
            or "primary purpose of this lesson" in pq.question.lower()
            for pq in pqs
        )
        tmpl_questions = tmpl.get("questions", [])
        if (len(pqs) < len(tmpl_questions) or has_placeholder) and tmpl_questions:
            for pq in pqs:
                db.delete(pq)
            db.flush()
            for q in tmpl_questions:
                practice_q = PracticeQuestion(
                    lesson_id=lesson.id,
                    question=q["question"],
                    question_type="mcq",
                    options=q["options"],
                    correct_answer=q["correct_answer"],
                    explanation=q.get("explanation", ""),
                )
                db.add(practice_q)

    db.commit()

def get_or_create_learning_path_for_skill(db: Session, skill_id: int) -> LearningPath:
    """
    Retrieves the existing learning path for a skill or dynamically creates a
    curated, multi-lesson path with study resources, practice questions, and a final quiz.
    """
    skill = db.query(Skill).filter(Skill.id == skill_id).first()
    if not skill:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Skill not found")

    path = db.query(LearningPath).filter(LearningPath.skill_id == skill_id).first()
    if path:
        _ensure_path_resources_and_questions(db, path, skill)
        return path

    skill_name = skill.name
    category = skill.category or "General"
    course_data = get_curated_or_generated_course(skill_name, category)

    # Create new LearningPath
    path = LearningPath(
        skill_id=skill.id,
        title=course_data.get("title", f"Mastering {skill_name}"),
        description=course_data.get("description", f"A structured curriculum designed for {skill_name} ({category})."),
        estimated_minutes=course_data.get("estimated_minutes", 120),
    )
    db.add(path)
    db.flush()

    lesson_templates = course_data.get("lessons", [])
    for item in lesson_templates:
        lesson = Lesson(
            learning_path_id=path.id,
            title=item["title"],
            content=item["content"],
            summary=item.get("summary", ""),
            video_url=item.get("video_url"),
            pdf_url=item.get("pdf_url"),
            doc_url=item.get("doc_url"),
            order=item["order"],
            estimated_minutes=item.get("estimated_minutes", 30),
        )
        db.add(lesson)
        db.flush()

        # Add resources
        for res in item.get("resources", []):
            resource = LearningResource(
                lesson_id=lesson.id,
                resource_type=res.get("type", "DOCS"),
                title=res.get("title", f"{skill_name} Resource"),
                url=res.get("url", "https://en.wikipedia.org"),
                source=res.get("source", "Web"),
                duration_minutes=res.get("duration", 15),
                is_primary=res.get("is_primary", False),
            )
            db.add(resource)

        # Add practice questions
        for q in item.get("questions", []):
            practice_q = PracticeQuestion(
                lesson_id=lesson.id,
                question=q["question"],
                question_type="mcq",
                options=q["options"],
                correct_answer=q["correct_answer"],
                explanation=q.get("explanation", ""),
            )
            db.add(practice_q)

    # Create Path-Level Timed Quiz
    quiz_data = course_data.get("quiz", {})
    quiz = Quiz(
        learning_path_id=path.id,
        title=quiz_data.get("title", f"{skill_name} Certification Assessment"),
        description=quiz_data.get("description", f"Comprehensive timed assessment for {skill_name}."),
        time_limit_minutes=quiz_data.get("time_limit_minutes", 15),
        passing_percentage=quiz_data.get("passing_percentage", 70),
        max_attempts=quiz_data.get("max_attempts", 10),
    )
    db.add(quiz)
    db.flush()

    quiz_questions_data = quiz_data.get("questions", [])
    for q_data in quiz_questions_data:
        qq = QuizQuestion(
            quiz_id=quiz.id,
            question_text=q_data["question"],
            question_type="mcq",
            options=q_data["options"],
            correct_answer=q_data["correct_answer"],
            explanation=q_data.get("explanation", ""),
            points=q_data.get("points", 20),
        )
        db.add(qq)

    db.commit()
    db.refresh(path)
    return path

def get_user_learning_dashboard(db: Session, user_id: int) -> LearningDashboardOut:
    """
    Computes real-time dynamic dashboard metrics for the authenticated user.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    progresses = db.query(UserLearningProgress).filter(UserLearningProgress.user_id == user_id).all()
    active_skills_list = []
    total_lessons_completed_count = 0
    total_completed_paths_count = 0

    for prog in progresses:
        path = db.query(LearningPath).filter(LearningPath.id == prog.learning_path_id).first()
        if not path:
            continue
        skill = db.query(Skill).filter(Skill.id == path.skill_id).first()
        skill_name = skill.name if skill else path.title

        lessons = (
            db.query(Lesson)
            .filter(Lesson.learning_path_id == path.id)
            .order_by(Lesson.order)
            .all()
        )
        total_lessons = len(lessons)
        completed_ids = _parse_completed(prog.completed_lessons)
        completed_count = len(completed_ids)
        total_lessons_completed_count += completed_count

        pct = (completed_count / total_lessons * 100.0) if total_lessons > 0 else 0.0
        if completed_count >= total_lessons and total_lessons > 0:
            total_completed_paths_count += 1

        # Find next uncompleted lesson
        next_lesson = None
        for l in lessons:
            if l.id not in completed_ids:
                next_lesson = l
                break

        active_skills_list.append(
            LearningDashboardSkill(
                skill_id=skill.id if skill else path.skill_id,
                skill_name=skill_name,
                learning_path_id=path.id,
                path_title=path.title,
                total_lessons=total_lessons,
                completed_lessons_count=completed_count,
                progress_percentage=round(pct, 1),
                next_lesson_id=next_lesson.id if next_lesson else (lessons[-1].id if lessons else None),
                next_lesson_title=next_lesson.title if next_lesson else "All Lessons Completed",
            )
        )

    # Quiz Attempts
    quiz_attempts = (
        db.query(QuizAttempt)
        .filter(QuizAttempt.user_id == user_id)
        .order_by(QuizAttempt.completed_at.desc())
        .all()
    )
    total_quiz_attempts = len(quiz_attempts)
    avg_score = (
        sum(a.percentage for a in quiz_attempts) / total_quiz_attempts
        if total_quiz_attempts > 0
        else 0.0
    )

    # Certificates
    certificates_count = db.query(Certificate).filter(Certificate.user_id == user_id).count()

    overall_pct = (
        sum(s.progress_percentage for s in active_skills_list) / len(active_skills_list)
        if active_skills_list
        else 0.0
    )

    recent_attempts_out = [
        QuizAttemptOut.model_validate(qa) for qa in quiz_attempts[:5]
    ]

    return LearningDashboardOut(
        active_skills=active_skills_list,
        total_enrolled_paths=len(progresses),
        total_completed_paths=total_completed_paths_count,
        total_lessons_completed=total_lessons_completed_count,
        overall_progress_percentage=round(overall_pct, 1),
        quiz_average_score=round(avg_score, 1),
        total_quiz_attempts=total_quiz_attempts,
        total_certificates=certificates_count,
        streak_days=user.streak_days or 1,
        total_xp=user.xp or 0,
        recent_quiz_attempts=recent_attempts_out,
    )

def grade_quiz_submission(
    db: Session, user: User, quiz_id: int, submission: QuizSubmission
) -> QuizResultOut:
    """
    Evaluates quiz submission, computes score & percentage, records QuizAttempt, and awards XP.
    """
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")

    questions = db.query(QuizQuestion).filter(QuizQuestion.quiz_id == quiz_id).all()
    if not questions:
        raise HTTPException(status_code=400, detail="Quiz has no questions")

    # Map submission
    answer_map = {item.question_id: item.answer for item in submission.answers}

    total_possible_marks = sum(q.points for q in questions)
    marks_obtained = 0
    feedback_items = []

    for q in questions:
        user_answer = answer_map.get(q.id, "")
        is_correct = user_answer.strip().lower() == q.correct_answer.strip().lower()
        points_earned = q.points if is_correct else 0
        marks_obtained += points_earned

        feedback_items.append(
            QuizFeedbackItem(
                question_id=q.id,
                question_text=q.question_text,
                user_answer=user_answer,
                correct_answer=q.correct_answer,
                is_correct=is_correct,
                explanation=q.explanation,
                points_earned=points_earned,
                points_possible=q.points,
            )
        )

    percentage = (marks_obtained / total_possible_marks * 100.0) if total_possible_marks > 0 else 0.0
    passed = percentage >= quiz.passing_percentage

    # Count prior attempts
    prior_attempts_count = (
        db.query(QuizAttempt)
        .filter(QuizAttempt.user_id == user.id, QuizAttempt.quiz_id == quiz_id)
        .count()
    )
    attempt_num = prior_attempts_count + 1

    now = datetime.now(timezone.utc)
    attempt = QuizAttempt(
        user_id=user.id,
        quiz_id=quiz.id,
        attempt_number=attempt_num,
        marks_obtained=marks_obtained,
        maximum_marks=total_possible_marks,
        percentage=round(percentage, 1),
        passed=passed,
        duration_seconds=submission.duration_seconds,
        answers_data=[item.model_dump() for item in submission.answers],
        completed_at=now,
    )
    db.add(attempt)
    db.commit()
    db.refresh(attempt)

    # Award XP if passed
    xp_earned = 0
    if passed:
        xp_earned = 50
        gamification_service.award_xp_idempotent(
            db, user.id, xp_earned, f"quiz_pass:{quiz.id}:attempt_{attempt_num}", f"Passed {quiz.title}"
        )
        gamification_service.check_and_award_achievements(db, user.id)

    return QuizResultOut(
        quiz_id=quiz.id,
        attempt_number=attempt_num,
        marks_obtained=marks_obtained,
        maximum_marks=total_possible_marks,
        percentage=round(percentage, 1),
        passed=passed,
        xp_earned=xp_earned,
        feedback=feedback_items,
        completed_at=now,
    )

def get_quiz_for_path(db: Session, path_id: int) -> Quiz:
    """
    Retrieves or creates a quiz for a given learning path.
    """
    quiz = db.query(Quiz).filter(Quiz.learning_path_id == path_id).first()
    if not quiz:
        path = db.query(LearningPath).filter(LearningPath.id == path_id).first()
        if not path:
            raise HTTPException(status_code=404, detail="Learning path not found")
        skill = db.query(Skill).filter(Skill.id == path.skill_id).first()
        skill_name = skill.name if skill else path.title
        category = skill.category if skill else "General"
        course_data = get_curated_or_generated_course(skill_name, category)
        quiz_data = course_data.get("quiz", {})

        quiz = Quiz(
            learning_path_id=path.id,
            title=quiz_data.get("title", f"{skill_name} Certification Assessment"),
            description=quiz_data.get("description", f"Comprehensive timed examination assessing fundamental and practical mastery of {skill_name}."),
            time_limit_minutes=quiz_data.get("time_limit_minutes", 15),
            passing_percentage=quiz_data.get("passing_percentage", 70),
            max_attempts=quiz_data.get("max_attempts", 10),
        )
        db.add(quiz)
        db.flush()

        quiz_questions_data = quiz_data.get("questions", [])
        for q_data in quiz_questions_data:
            qq = QuizQuestion(
                quiz_id=quiz.id,
                question_text=q_data["question"],
                question_type="mcq",
                options=q_data["options"],
                correct_answer=q_data["correct_answer"],
                explanation=q_data.get("explanation", ""),
                points=q_data.get("points", 20),
            )
            db.add(qq)

        db.commit()
        db.refresh(quiz)
    return quiz
