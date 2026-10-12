from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional, List, Dict, Any

from ..db.models import (
    User,
    Skill,
    UserSkillOffered,
    UserSkillWanted,
    Booking,
    Transaction,
    Review,
    LearningPath,
    Lesson,
    PracticeAttempt,
    UserLearningProgress,
    Certificate,
)
from ..schemas.passport import (
    PassportProfile,
    PassportSkill,
    PassportCertificate,
    PassportPracticeSummary,
    PassportLearningSummary,
    PassportExchangeSummary,
    SkillPassportResponse,
)

def get_skill_passport(db: Session, user_id: int, is_public: bool = False) -> Optional[SkillPassportResponse]:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return None

    # 1. Profile
    location_str = None
    if user.lat is not None and user.lng is not None:
        location_str = f"{round(user.lat, 2)}, {round(user.lng, 2)}"
    elif hasattr(user, "title") and user.title:
        location_str = "Verified Community Member"

    profile = PassportProfile(
        user_id=user.id,
        name=user.name,
        email=None if is_public else user.email,
        title=user.title or "Skill Enthusiast",
        bio="Passionate learner and skill exchanger.",
        avatar_url=user.avatar_url,
        location=location_str,
        xp=user.xp or 0,
        streak_days=user.streak_days or 0,
        credits=None if is_public else (user.credits or 0),
    )

    # 2. Certificates
    certs_query = db.query(Certificate).filter(
        Certificate.user_id == user_id,
        Certificate.status == "valid"
    ).order_by(Certificate.issued_at.desc()).all()

    certificates: List[PassportCertificate] = []
    for c in certs_query:
        skill_name = c.skill.name if c.skill else "Specialized Skill"
        certificates.append(
            PassportCertificate(
                certificate_id=c.id,
                certificate_number=c.certificate_number,
                title=c.title,
                skill=skill_name,
                skill_id=c.skill_id,
                issued_at=c.issued_at,
                verification_code=c.verification_code,
                status=c.status,
            )
        )

    # 3. Learning Summary & Path progress
    all_paths = db.query(LearningPath).all()
    user_progress_list = db.query(UserLearningProgress).filter(
        UserLearningProgress.user_id == user_id
    ).all()

    progress_by_path_id: Dict[int, UserLearningProgress] = {
        up.learning_path_id: up for up in user_progress_list
    }

    total_lessons_available = 0
    total_lessons_completed = 0
    completed_paths_count = 0
    active_paths_count = 0

    cert_path_ids = {c.learning_path_id for c in certs_query}

    for path in all_paths:
        path_lessons_count = len(path.lessons)
        total_lessons_available += path_lessons_count

        prog = progress_by_path_id.get(path.id)
        if prog or path.id in cert_path_ids:
            completed_ids = [int(x.strip()) for x in (prog.completed_lessons if prog else "").split(",") if x.strip().isdigit()]
            total_lessons_completed += len(completed_ids)

            if path.id in cert_path_ids or (prog and prog.completed_at is not None) or (path_lessons_count > 0 and len(completed_ids) >= path_lessons_count):
                completed_paths_count += 1
            else:
                active_paths_count += 1

    overall_progress = 0.0
    if total_lessons_available > 0:
        overall_progress = round(min(100.0, (total_lessons_completed / total_lessons_available) * 100.0), 1)

    learning_summary = PassportLearningSummary(
        active_paths=active_paths_count,
        completed_paths=completed_paths_count,
        total_lessons_completed=total_lessons_completed,
        total_lessons_available=total_lessons_available,
        overall_progress=overall_progress,
    )

    # 4. Practice Summary
    attempts = db.query(PracticeAttempt).filter(PracticeAttempt.user_id == user_id).all()
    total_attempts = len(attempts)
    passed_attempts = sum(1 for a in attempts if a.score >= 70)
    avg_score = round(sum(a.score for a in attempts) / total_attempts, 1) if total_attempts > 0 else None
    highest_score = max((a.score for a in attempts), default=None)
    lessons_practiced = len(set(a.lesson_id for a in attempts))

    practice_summary = PassportPracticeSummary(
        total_attempts=total_attempts,
        passed_attempts=passed_attempts,
        average_score=avg_score,
        highest_score=highest_score,
        lessons_practiced=lessons_practiced,
    )

    # 5. Skills & Deterministic Level Calculation
    offered_skill_ids = [s.skill_id for s in db.query(UserSkillOffered.skill_id).filter(UserSkillOffered.user_id == user_id).all()]
    wanted_skill_ids = [s.skill_id for s in db.query(UserSkillWanted.skill_id).filter(UserSkillWanted.user_id == user_id).all()]
    learning_skill_ids = [p.skill_id for p in all_paths if p.id in progress_by_path_id]
    certified_skill_ids = [c.skill_id for c in certs_query]

    unique_skill_ids = list(dict.fromkeys(offered_skill_ids + certified_skill_ids + learning_skill_ids + wanted_skill_ids))

    # If user has no skills mapped yet, ensure any skill associated with an existing path is checked
    skills_query = db.query(Skill).filter(Skill.id.in_(unique_skill_ids)).all() if unique_skill_ids else []

    passport_skills: List[PassportSkill] = []
    for sk in skills_query:
        sk_paths = [p for p in all_paths if p.skill_id == sk.id]
        sk_total_lessons = sum(len(p.lessons) for p in sk_paths)
        sk_completed_lessons = 0
        sk_completed_paths = 0

        for p in sk_paths:
            prog = progress_by_path_id.get(p.id)
            if prog:
                c_ids = [int(x.strip()) for x in (prog.completed_lessons or "").split(",") if x.strip().isdigit()]
                sk_completed_lessons += len(c_ids)
                if prog.completed_at is not None or (len(p.lessons) > 0 and len(c_ids) >= len(p.lessons)):
                    sk_completed_paths += 1

        sk_progress = 0.0
        if sk_total_lessons > 0:
            sk_progress = round(min(100.0, (sk_completed_lessons / sk_total_lessons) * 100.0), 1)

        sk_certs_count = sum(1 for c in certs_query if c.skill_id == sk.id)
        is_certified = sk_certs_count > 0

        # Practice performance for lessons under this skill's paths
        sk_lesson_ids = {l.id for p in sk_paths for l in p.lessons}
        sk_attempts = [a for a in attempts if a.lesson_id in sk_lesson_ids]
        sk_practice_avg = round(sum(a.score for a in sk_attempts) / len(sk_attempts), 1) if sk_attempts else None

        # Deterministic Skill Level Rules
        if is_certified or (sk_completed_paths > 0 and sk_progress >= 100.0 and (sk_practice_avg or 0) >= 80.0):
            level = "Advanced"
        elif sk_completed_paths > 0 or sk_progress >= 50.0 or (sk_practice_avg is not None and sk_practice_avg >= 70.0):
            level = "Intermediate"
        else:
            level = "Beginner"

        passport_skills.append(
            PassportSkill(
                skill_id=sk.id,
                skill_name=sk.name,
                category=sk.category,
                level=level,
                learning_progress=sk_progress,
                completed_learning_paths=sk_completed_paths,
                certificates_count=sk_certs_count,
                practice_average=sk_practice_avg,
                is_certified=is_certified,
            )
        )

    # 6. Exchange Summary
    offered_count = len(offered_skill_ids)
    requested_count = len(wanted_skill_ids)

    mentor_bookings = db.query(Booking).filter(
        Booking.mentor_id == user_id,
        Booking.status == "completed"
    ).count()

    mentee_bookings = db.query(Booking).filter(
        Booking.mentee_id == user_id,
        Booking.status == "completed"
    ).count()

    total_exchanges = mentor_bookings + mentee_bookings

    credits_earned = None
    credits_spent = None
    if not is_public:
        pos_tx = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == user_id,
            Transaction.amount > 0
        ).scalar() or 0

        neg_tx = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == user_id,
            Transaction.amount < 0
        ).scalar() or 0

        credits_earned = int(pos_tx)
        credits_spent = abs(int(neg_tx))

    # Ratings & Reviews
    reviews_received = db.query(Review).filter(Review.reviewee_id == user_id).all()
    if reviews_received:
        avg_rating = round(sum(r.rating for r in reviews_received) / len(reviews_received), 1)
        total_rev = len(reviews_received)
    else:
        avg_rating = round(user.rating or 5.0, 1)
        total_rev = user.reviews or 0

    exchange_summary = PassportExchangeSummary(
        skills_offered_count=offered_count,
        skills_requested_count=requested_count,
        completed_bookings_as_mentor=mentor_bookings,
        completed_bookings_as_mentee=mentee_bookings,
        total_completed_exchanges=total_exchanges,
        credits_earned=credits_earned,
        credits_spent=credits_spent,
        average_rating=avg_rating,
        total_reviews=total_rev,
    )

    return SkillPassportResponse(
        profile=profile,
        learning_summary=learning_summary,
        practice_summary=practice_summary,
        skills=passport_skills,
        certificates=certificates,
        exchange_summary=exchange_summary,
        is_public_view=is_public,
    )
