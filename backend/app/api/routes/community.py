from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from ..deps import SessionDep, CurrentUser, OptionalCurrentUser
from ...db.models import (
    User,
    Skill,
    UserSkillOffered,
    UserSkillWanted,
    Booking,
    Review,
    Certificate,
    UserLearningProgress,
    LearningPath,
    UserBlock,
)
from ...schemas.community import (
    CommunityActivityItem,
    CommunityTrustIndicators,
    CommunityProfileResponse,
    CommunityDiscoveryPeer,
    CommunityDiscoveryResponse,
)
from ...utils.location import haversine

router = APIRouter()

@router.get("/activity", response_model=List[CommunityActivityItem])
@router.get("/feed", response_model=List[CommunityActivityItem])
def get_community_activity(
    db: SessionDep,
    current_user: OptionalCurrentUser = None,
    limit: int = Query(20, ge=1, le=50),
):
    """
    Derives real community activities from existing database records:
    Certificates, completed learning paths, completed bookings, and reviews.
    """
    activities: List[CommunityActivityItem] = []
    include_test = bool(current_user and current_user.is_test_user)

    # 1. Earned Certificates
    certs_q = (
        db.query(Certificate, User, Skill)
        .join(User, Certificate.user_id == User.id)
        .join(Skill, Certificate.skill_id == Skill.id)
        .filter(Certificate.status == "valid")
    )
    if not include_test:
        certs_q = certs_q.filter(User.is_test_user == False)
    certs = certs_q.order_by(Certificate.issued_at.desc()).limit(limit).all()

    for cert, user, skill in certs:
        activities.append(
            CommunityActivityItem(
                id=f"cert_{cert.id}",
                type="certificate",
                title=f"{user.name} earned a Verified Certificate!",
                description=f"Earned credential {cert.certificate_number} for completing {cert.title}.",
                timestamp=cert.issued_at,
                user_id=user.id,
                user_name=user.name,
                user_avatar=user.avatar_url,
                skill_id=skill.id,
                skill_name=skill.name,
            )
        )

    # 2. Completed Learning Paths
    progresses_q = (
        db.query(UserLearningProgress, User, LearningPath)
        .join(User, UserLearningProgress.user_id == User.id)
        .join(LearningPath, UserLearningProgress.learning_path_id == LearningPath.id)
        .filter(UserLearningProgress.completed_at.isnot(None))
    )
    if not include_test:
        progresses_q = progresses_q.filter(User.is_test_user == False)
    progresses = progresses_q.order_by(UserLearningProgress.completed_at.desc()).limit(limit).all()

    for p, user, path in progresses:
        activities.append(
            CommunityActivityItem(
                id=f"prog_{p.id}",
                type="path_completed",
                title=f"{user.name} completed a learning curriculum!",
                description=f"Finished all lessons in '{path.title}'.",
                timestamp=p.completed_at,
                user_id=user.id,
                user_name=user.name,
                user_avatar=user.avatar_url,
                skill_id=path.skill_id,
                skill_name=path.title,
            )
        )

    # 3. Completed Skill Exchanges
    completed_bookings_q = (
        db.query(Booking, User, Skill)
        .join(User, Booking.mentor_id == User.id)
        .join(Skill, Booking.skill_id == Skill.id)
        .filter(Booking.status == "completed")
    )
    if not include_test:
        completed_bookings_q = completed_bookings_q.filter(User.is_test_user == False)
    completed_bookings = completed_bookings_q.order_by(Booking.date.desc()).limit(limit).all()

    for booking, mentor, skill in completed_bookings:
        mentee = db.query(User).filter(User.id == booking.mentee_id).first()
        if not include_test and mentee and mentee.is_test_user:
            continue
        mentee_name = mentee.name if mentee else "Learner"
        activities.append(
            CommunityActivityItem(
                id=f"booking_{booking.id}",
                type="exchange_completed",
                title=f"Skill exchange completed!",
                description=f"{mentor.name} and {mentee_name} successfully held a 1-on-1 session in {skill.name}.",
                timestamp=booking.date or datetime.now(),
                user_id=mentor.id,
                user_name=mentor.name,
                user_avatar=mentor.avatar_url,
                skill_id=skill.id,
                skill_name=skill.name,
            )
        )

    # 4. Verified Reviews
    reviews_q = (
        db.query(Review, User)
        .join(User, Review.reviewee_id == User.id)
    )
    if not include_test:
        reviews_q = reviews_q.filter(User.is_test_user == False)
    reviews = reviews_q.order_by(Review.created_at.desc()).limit(limit).all()

    for rev, reviewee in reviews:
        reviewer = db.query(User).filter(User.id == rev.reviewer_id).first()
        if not include_test and reviewer and reviewer.is_test_user:
            continue
        rev_name = reviewer.name if reviewer else "Community Member"
        activities.append(
            CommunityActivityItem(
                id=f"rev_{rev.id}",
                type="review",
                title=f"{reviewee.name} received a {rev.rating}★ review!",
                description=f'"{rev.comment}" — by {rev_name}',
                timestamp=rev.created_at,
                user_id=reviewee.id,
                user_name=reviewee.name,
                user_avatar=reviewee.avatar_url,
                rating=rev.rating,
            )
        )

    # Sort deterministically by timestamp descending
    activities.sort(key=lambda a: a.timestamp, reverse=True)
    return activities[:limit]

@router.get("/activity/user/{user_id}", response_model=List[CommunityActivityItem])
def get_user_activity(user_id: int, db: SessionDep, limit: int = Query(10, ge=1, le=30)):
    """User-specific community activity derived from real records."""
    activities: List[CommunityActivityItem] = []

    # Certificates
    certs = (
        db.query(Certificate, User, Skill)
        .join(User, Certificate.user_id == User.id)
        .join(Skill, Certificate.skill_id == Skill.id)
        .filter(Certificate.user_id == user_id, Certificate.status == "valid")
        .order_by(Certificate.issued_at.desc())
        .limit(limit)
        .all()
    )
    for cert, user, skill in certs:
        activities.append(
            CommunityActivityItem(
                id=f"cert_{cert.id}",
                type="certificate",
                title="Earned Verified Certificate",
                description=f"Earned credential {cert.certificate_number} for {cert.title}.",
                timestamp=cert.issued_at,
                user_id=user.id,
                user_name=user.name,
                user_avatar=user.avatar_url,
                skill_id=skill.id,
                skill_name=skill.name,
            )
        )

    # Completed bookings
    bookings = (
        db.query(Booking, Skill)
        .join(Skill, Booking.skill_id == Skill.id)
        .filter(
            ((Booking.mentor_id == user_id) | (Booking.mentee_id == user_id)),
            Booking.status == "completed"
        )
        .order_by(Booking.date.desc())
        .limit(limit)
        .all()
    )
    for b, skill in bookings:
        role = "Mentor" if b.mentor_id == user_id else "Mentee"
        activities.append(
            CommunityActivityItem(
                id=f"b_{b.id}",
                type="exchange_completed",
                title=f"Skill Exchange as {role}",
                description=f"Completed exchange session for {skill.name}.",
                timestamp=b.date or datetime.now(),
                user_id=user_id,
                user_name="",
                skill_id=skill.id,
                skill_name=skill.name,
            )
        )

    activities.sort(key=lambda a: a.timestamp, reverse=True)
    return activities[:limit]

@router.get("/profile/{user_id}", response_model=CommunityProfileResponse)
@router.get("/trust/{user_id}", response_model=CommunityProfileResponse)
def get_community_profile(user_id: int, db: SessionDep, current_user: CurrentUser):
    """
    Public community profile displaying verifiable trust indicators without leaking
    sensitive fields like email or wallet credits.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Trust indicators
    cert_count = db.query(Certificate).filter(Certificate.user_id == user_id, Certificate.status == "valid").count()
    completed_exchanges = db.query(Booking).filter(
        ((Booking.mentor_id == user_id) | (Booking.mentee_id == user_id)),
        Booking.status == "completed"
    ).count()

    skills_offered_rows = db.query(UserSkillOffered, Skill).join(Skill, UserSkillOffered.skill_id == Skill.id).filter(UserSkillOffered.user_id == user_id).all()
    skills_offered = [{"id": s.id, "name": s.name, "category": s.category} for _, s in skills_offered_rows]

    skills_wanted_rows = db.query(UserSkillWanted, Skill).join(Skill, UserSkillWanted.skill_id == Skill.id).filter(UserSkillWanted.user_id == user_id).all()
    skills_wanted = [{"id": s.id, "name": s.name, "category": s.category} for _, s in skills_wanted_rows]

    completed_paths = db.query(UserLearningProgress).filter(
        UserLearningProgress.user_id == user_id,
        UserLearningProgress.completed_at.isnot(None)
    ).count()

    # Progress calculation
    all_progress = db.query(UserLearningProgress).filter(UserLearningProgress.user_id == user_id).all()
    progress_pct = 0.0
    if all_progress:
        total_p = 0.0
        for p in all_progress:
            path = db.query(LearningPath).filter(LearningPath.id == p.learning_path_id).first()
            if path and path.lessons:
                c_ids = [int(x.strip()) for x in (p.completed_lessons or "").split(",") if x.strip().isdigit()]
                total_p += (len(c_ids) / len(path.lessons)) * 100.0
        progress_pct = round(total_p / len(all_progress), 1)

    is_verified_mentor = (cert_count >= 1) or (completed_exchanges >= 1 and user.rating >= 4.5)

    trust_indicators = CommunityTrustIndicators(
        verified_certificates_count=cert_count,
        completed_exchanges=completed_exchanges,
        rating=user.rating or 5.0,
        review_count=user.reviews or 0,
        skills_offered_count=len(skills_offered),
        skills_learned_count=completed_paths,
        learning_progress_percent=progress_pct,
        is_verified_mentor=is_verified_mentor,
    )

    # Check block state
    is_blocked = db.query(UserBlock).filter(
        UserBlock.blocker_id == current_user.id,
        UserBlock.blocked_user_id == user_id
    ).first() is not None

    user_activity = get_user_activity(user_id=user_id, db=db, limit=5)

    return CommunityProfileResponse(
        user_id=user.id,
        name=user.name,
        title=user.title,
        avatar_url=user.avatar_url,
        bio=f"Active community learner and contributor. Specializing in {skills_offered[0]['name'] if skills_offered else 'Skill Exchange'}.",
        trust_indicators=trust_indicators,
        skills_offered=skills_offered,
        skills_wanted=skills_wanted,
        recent_activity=user_activity,
        is_blocked=is_blocked,
    )

@router.get("/discovery", response_model=CommunityDiscoveryResponse)
def get_community_discovery(db: SessionDep, current_user: OptionalCurrentUser = None):
    """
    Returns categorized discovery peers:
    1. Mentors for you (teaching what you want or are learning)
    2. Learning peers (learning similar or same paths)
    3. Nearby skill partners
    """
    # Blocked users filter
    blocked_ids = set()
    if current_user:
        blocked_ids = {b.blocked_user_id for b in db.query(UserBlock).filter(UserBlock.blocker_id == current_user.id).all()}
        blocked_ids.add(current_user.id)

    # User's wanted & learning skills
    wanted_skills = set()
    user_path_ids = set()
    if current_user:
        wanted_skills = {w.skill_id for w in db.query(UserSkillWanted).filter(UserSkillWanted.user_id == current_user.id).all()}
        user_progress = db.query(UserLearningProgress).filter(UserLearningProgress.user_id == current_user.id).all()
        user_path_ids = {p.learning_path_id for p in user_progress}

    # 1. Mentors for you
    mentors_for_you: List[CommunityDiscoveryPeer] = []
    mentor_query = (
        db.query(User, Skill)
        .join(UserSkillOffered, User.id == UserSkillOffered.user_id)
        .join(Skill, UserSkillOffered.skill_id == Skill.id)
        .filter(User.is_test_user == False)
    )
    if blocked_ids:
        mentor_query = mentor_query.filter(User.id.notin_(blocked_ids))
    mentor_candidates = mentor_query.all()

    seen_mentors = set()
    for mentor, skill in mentor_candidates:
        if mentor.id in seen_mentors:
            continue
        dist = None
        if current_user and current_user.lat and current_user.lng and mentor.lat and mentor.lng:
            dist = round(haversine(current_user.lat, current_user.lng, mentor.lat, mentor.lng), 1)

        cert_count = db.query(Certificate).filter(Certificate.user_id == mentor.id, Certificate.status == "valid").count()
        badges = []
        if cert_count > 0:
            badges.append(f"{cert_count} Certificate{'s' if cert_count > 1 else ''}")
        if mentor.rating >= 4.8 and mentor.reviews >= 3:
            badges.append("Top Rated")

        reason = f"Teaches {skill.name}"
        if skill.id in wanted_skills:
            reason = f"Matches your wanted skill: {skill.name}"
        elif dist is not None and dist <= 10.0:
            reason = f"Nearby mentor ({dist} km) for {skill.name}"

        seen_mentors.add(mentor.id)
        mentors_for_you.append(
            CommunityDiscoveryPeer(
                user_id=mentor.id,
                name=mentor.name,
                title=mentor.title,
                avatar_url=mentor.avatar_url,
                rating=mentor.rating or 5.0,
                review_count=mentor.reviews or 0,
                distance_km=dist,
                common_skill=skill.name,
                reason=reason,
                trust_badges=badges,
            )
        )

    # 2. Learning peers
    learning_peers: List[CommunityDiscoveryPeer] = []
    peer_query = (
        db.query(User, LearningPath)
        .join(UserLearningProgress, User.id == UserLearningProgress.user_id)
        .join(LearningPath, UserLearningProgress.learning_path_id == LearningPath.id)
        .filter(User.is_test_user == False)
    )
    if blocked_ids:
        peer_query = peer_query.filter(User.id.notin_(blocked_ids))
    peer_candidates = peer_query.all()

    seen_peers = set()
    for peer, path in peer_candidates:
        if peer.id in seen_peers:
            continue
        dist = None
        if current_user and current_user.lat and current_user.lng and peer.lat and peer.lng:
            dist = round(haversine(current_user.lat, current_user.lng, peer.lat, peer.lng), 1)

        reason = f"Learning {path.title}"
        if path.id in user_path_ids:
            reason = f"Studying the same curriculum: {path.title}"

        seen_peers.add(peer.id)
        learning_peers.append(
            CommunityDiscoveryPeer(
                user_id=peer.id,
                name=peer.name,
                title=peer.title,
                avatar_url=peer.avatar_url,
                rating=peer.rating or 5.0,
                review_count=peer.reviews or 0,
                distance_km=dist,
                common_skill=path.title,
                reason=reason,
                trust_badges=["Active Learner"],
            )
        )

    # 3. Nearby partners
    nearby_partners: List[CommunityDiscoveryPeer] = []
    all_others_query = db.query(User).filter(User.is_test_user == False)
    if blocked_ids:
        all_others_query = all_others_query.filter(User.id.notin_(blocked_ids))
    all_others = all_others_query.all()

    for u in all_others:
        if current_user and current_user.lat and current_user.lng and u.lat and u.lng:
            dist = round(haversine(current_user.lat, current_user.lng, u.lat, u.lng), 1)
            if dist <= 25.0:
                badges = []
                if u.rating >= 4.8:
                    badges.append("Top Rated")
                nearby_partners.append(
                    CommunityDiscoveryPeer(
                        user_id=u.id,
                        name=u.name,
                        title=u.title,
                        avatar_url=u.avatar_url,
                        rating=u.rating or 5.0,
                        review_count=u.reviews or 0,
                        distance_km=dist,
                        reason=f"Located in your local area ({dist} km away)",
                        trust_badges=badges,
                    )
                )
        elif not current_user:
            nearby_partners.append(
                CommunityDiscoveryPeer(
                    user_id=u.id,
                    name=u.name,
                    title=u.title,
                    avatar_url=u.avatar_url,
                    rating=u.rating or 5.0,
                    review_count=u.reviews or 0,
                    distance_km=None,
                    reason="Community member",
                    trust_badges=["Active Member"],
                )
            )

    return CommunityDiscoveryResponse(
        mentors_for_you=mentors_for_you,
        learning_peers=learning_peers,
        nearby_partners=nearby_partners,
    )
