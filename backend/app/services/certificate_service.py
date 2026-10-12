import secrets
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from ..db.models import Certificate, LearningPath, Lesson, UserLearningProgress, User, Skill, Notification

def _parse_completed_ids(completed_str: str) -> list[int]:
    if not completed_str:
        return []
    return [int(i) for i in completed_str.split(",") if i]

def _generate_certificate_number(db: Session, year: int) -> str:
    count = db.query(Certificate).count() + 1
    random_suffix = secrets.token_hex(2).upper()
    return f"LSE-CERT-{year}-{count:05d}-{random_suffix}"

def _generate_verification_code() -> str:
    return secrets.token_hex(16)

def verify_and_issue_certificate(db: Session, user: User, learning_path_id: int) -> Certificate:
    # 1. Verify learning path exists
    learning_path = db.query(LearningPath).filter(LearningPath.id == learning_path_id).first()
    if not learning_path:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Learning path not found")

    # 2. Check if certificate already exists (idempotent duplicate prevention)
    existing_cert = (
        db.query(Certificate)
        .filter(Certificate.user_id == user.id, Certificate.learning_path_id == learning_path_id)
        .first()
    )
    if existing_cert:
        _enrich_certificate(existing_cert, db)
        return existing_cert

    # 3. Verify user learning progress
    progress = (
        db.query(UserLearningProgress)
        .filter(
            UserLearningProgress.user_id == user.id,
            UserLearningProgress.learning_path_id == learning_path_id,
        )
        .first()
    )
    if not progress:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Learning path has not been started by this user",
        )

    # 4. Verify all lessons are completed
    total_lessons = db.query(Lesson).filter(Lesson.learning_path_id == learning_path_id).count()
    completed_ids = _parse_completed_ids(progress.completed_lessons)

    if total_lessons == 0 or len(completed_ids) < total_lessons:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot issue certificate: only {len(completed_ids)} of {total_lessons} lessons completed",
        )

    completed_at = progress.completed_at or datetime.now(timezone.utc)
    now = datetime.now(timezone.utc)

    # 5. Create new certificate
    cert_number = _generate_certificate_number(db, now.year)
    verification_code = _generate_verification_code()

    certificate = Certificate(
        certificate_number=cert_number,
        verification_code=verification_code,
        user_id=user.id,
        learning_path_id=learning_path_id,
        skill_id=learning_path.skill_id,
        title=f"Certificate of Completion - {learning_path.title}",
        description=f"Awarded to {user.name} for successfully mastering {learning_path.title}.",
        issued_at=now,
        completed_at=completed_at,
        status="valid",
        created_at=now,
    )

    db.add(certificate)
    db.commit()
    db.refresh(certificate)

    from . import notification_service
    notification_service.create_notification(
        db=db,
        user_id=user.id,
        title="Your Certificate is Ready!",
        message=f"Your verified cryptographic certificate for {learning_path.title} is ready.",
        notification_type="CERTIFICATE_ISSUED",
        target_id=certificate.id,
    )

    # Award +150 XP for earning certificate (idempotent)
    from . import gamification_service
    gamification_service.award_xp_idempotent(
        db, user.id, 150, f"cert:{certificate.id}", f"Earned verified certificate: {certificate.title}"
    )
    gamification_service.check_and_award_achievements(db, user.id)

    _enrich_certificate(certificate, db)
    return certificate

def _enrich_certificate(cert: Certificate, db: Session):
    user = db.query(User).filter(User.id == cert.user_id).first()
    skill = db.query(Skill).filter(Skill.id == cert.skill_id).first()
    path = db.query(LearningPath).filter(LearningPath.id == cert.learning_path_id).first()
    setattr(cert, "recipient_name", user.name if user else "Student")
    setattr(cert, "skill_name", skill.name if skill else "")
    setattr(cert, "learning_path_title", path.title if path else "")

def get_user_certificates(db: Session, user_id: int) -> list[Certificate]:
    certs = (
        db.query(Certificate)
        .filter(Certificate.user_id == user_id)
        .order_by(Certificate.issued_at.desc())
        .all()
    )
    for c in certs:
        _enrich_certificate(c, db)
    return certs

def get_certificate_by_id(db: Session, certificate_id: int, user_id: int) -> Certificate:
    certificate = (
        db.query(Certificate)
        .filter(Certificate.id == certificate_id, Certificate.user_id == user_id)
        .first()
    )
    if not certificate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Certificate not found or access denied",
        )
    _enrich_certificate(certificate, db)
    return certificate

def verify_certificate_code(db: Session, verification_code: str) -> dict:
    certificate = (
        db.query(Certificate)
        .filter(
            (Certificate.verification_code == verification_code) |
            (Certificate.certificate_number == verification_code)
        )
        .first()
    )
    if not certificate or certificate.status != "valid":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid or unverified certificate code",
        )

    user = db.query(User).filter(User.id == certificate.user_id).first()
    skill = db.query(Skill).filter(Skill.id == certificate.skill_id).first()
    learning_path = db.query(LearningPath).filter(LearningPath.id == certificate.learning_path_id).first()

    return {
        "valid": True,
        "certificate_number": certificate.certificate_number,
        "title": certificate.title,
        "skill": skill.name if skill else (learning_path.title if learning_path else "Skill Exchange"),
        "recipient_name": user.name if user else "Verified Student",
        "issued_at": certificate.issued_at,
        "status": certificate.status,
    }
