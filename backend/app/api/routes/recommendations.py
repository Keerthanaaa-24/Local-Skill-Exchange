from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Set
import math

from ..deps import SessionDep, CurrentUser
from ...db.models import (
    User,
    Skill,
    UserSkillOffered,
    UserSkillWanted,
    Booking,
    UserLearningProgress,
    LearningPath,
    Certificate,
)
from ...schemas.recommendation import RecommendationItem
from ...services import ai_coach_service

router = APIRouter()

@router.get("/coach/summary")
def get_ai_coach_summary(db: SessionDep, current_user: CurrentUser) -> Dict[str, Any]:
    """
    Get full AI Skill Coach personalized analysis, skill gaps, hero recommendations,
    practice diagnostics, and exchange matches.
    """
    return ai_coach_service.get_coach_summary(db, current_user)

@router.get("/coach/roadmap")
def get_ai_coach_roadmap(db: SessionDep, current_user: CurrentUser) -> List[Dict[str, Any]]:
    """
    Get step-by-step personalized learning roadmap.
    """
    return ai_coach_service.generate_personalized_roadmap(db, current_user)

@router.get("/coach/skill-gaps")
def get_ai_coach_skill_gaps(db: SessionDep, current_user: CurrentUser) -> Dict[str, Any]:
    """
    Get detailed skill-gap breakdown.
    """
    return ai_coach_service.analyze_user_skill_gaps(db, current_user)

@router.get("/coach/diagnostics")
def get_ai_coach_diagnostics(db: SessionDep, current_user: CurrentUser) -> List[Dict[str, Any]]:
    """
    Get practice diagnostic insights and weak-topic revision recommendations.
    """
    return ai_coach_service.generate_practice_diagnostics(db, current_user)

@router.get("/coach/growth")
def get_ai_coach_growth(db: SessionDep, current_user: CurrentUser) -> Dict[str, Any]:
    """
    Get AI Skill Growth velocity, accuracy improvements, and mastery index.
    """
    return ai_coach_service.calculate_skill_growth(db, current_user)

@router.get("/coach/daily-goal")
def get_ai_coach_daily_goal(db: SessionDep, current_user: CurrentUser) -> Dict[str, Any]:
    """
    Get personalized daily learning/practice objective based on real user state.
    """
    return ai_coach_service.get_daily_goal(db, current_user)

@router.get("/coach/daily-plan")
def get_ai_coach_daily_plan(db: SessionDep, current_user: CurrentUser) -> Dict[str, Any]:
    """
    Get structured 1-2-3 daily action plan.
    """
    plan = ai_coach_service.generate_daily_plan(db, current_user)
    return {"daily_plan": plan}

@router.get("/coach/weekly-insights")
def get_ai_coach_weekly_insights(db: SessionDep, current_user: CurrentUser) -> Dict[str, Any]:
    """
    Get rolling 7-day AI learning and practice activity insights.
    """
    return ai_coach_service.get_weekly_insights(db, current_user)

@router.get("/coach/adaptive")
def get_ai_coach_adaptive(db: SessionDep, current_user: CurrentUser) -> List[Dict[str, Any]]:
    """
    Get adaptive next-step recommendations categorized by intent.
    """
    return ai_coach_service.generate_adaptive_recommendations(db, current_user)

@router.get("/coach/exchanges")
def get_ai_coach_exchanges(db: SessionDep, current_user: CurrentUser) -> List[Dict[str, Any]]:
    """
    Get 2-way peer skill exchange matches.
    """
    return ai_coach_service.generate_exchange_suggestions(db, current_user)

def haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate great-circle distance between two points (km)."""
    R = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1 - a))

def compute_personalized_score(
    distance_km: float | None,
    mentor_rating: float | None,
    review_count: int | None,
    is_learning_goal: bool,
    same_category: bool,
) -> float:
    # 1. Rating contribution (up to 40 pts)
    rating_score = ((mentor_rating or 5.0) / 5.0) * 40.0

    # 2. Review volume contribution (up to 20 pts)
    review_score = min(20.0, (math.log10((review_count or 0) + 1) / math.log10(51)) * 20.0)

    # 3. Proximity contribution (up to 20 pts)
    distance_score = 10.0
    if distance_km is not None:
        distance_score = max(0.0, (50.0 - distance_km) / 50.0) * 20.0

    # 4. Personal alignment bonus (up to 20 pts)
    alignment_score = 0.0
    if is_learning_goal:
        alignment_score += 15.0
    elif same_category:
        alignment_score += 10.0

    total = rating_score + review_score + distance_score + alignment_score
    return round(min(100.0, total), 1)

@router.get("/")
@router.get("")
@router.get("/matches")
def get_recommendations(
    db: SessionDep,
    current_user: CurrentUser,
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Results per page, max 100"),
) -> Dict[str, Any]:
    """
    Return paginated, intelligent skill & mentor recommendations tailored to the user.
    Integrates learning progress, certificates, wanted/offered skills, and proximity.
    """
    # 1. User's wanted skills
    wanted_rows = db.query(UserSkillWanted).filter(UserSkillWanted.user_id == current_user.id).all()
    wanted_skill_ids: Set[int] = {r.skill_id for r in wanted_rows}

    # 2. User's offered skills
    offered_rows = db.query(UserSkillOffered).filter(UserSkillOffered.user_id == current_user.id).all()
    offered_skill_ids: Set[int] = {r.skill_id for r in offered_rows}

    # 3. User's learning progress
    user_progress = db.query(UserLearningProgress).filter(UserLearningProgress.user_id == current_user.id).all()
    learning_skills_info: Dict[int, Dict[str, Any]] = {}
    learning_categories: Set[str] = set()

    for p in user_progress:
        path = db.query(LearningPath).filter(LearningPath.id == p.learning_path_id).first()
        if path:
            skill = db.query(Skill).filter(Skill.id == path.skill_id).first()
            if skill:
                c_ids = [int(x.strip()) for x in (p.completed_lessons or "").split(",") if x.strip().isdigit()]
                total_lessons = len(path.lessons)
                pct = round((len(c_ids) / total_lessons) * 100.0) if total_lessons > 0 else 0
                is_done = p.completed_at is not None or (total_lessons > 0 and len(c_ids) >= total_lessons)
                learning_skills_info[skill.id] = {
                    "skill_name": skill.name,
                    "percent": pct,
                    "is_done": is_done,
                    "category": skill.category,
                }
                if skill.category:
                    learning_categories.add(skill.category.lower())

    # 4. User's certificates
    user_certs = db.query(Certificate).filter(
        Certificate.user_id == current_user.id,
        Certificate.status == "valid"
    ).all()
    certified_skill_ids: Set[int] = {c.skill_id for c in user_certs}

    # 5. Booked mentors (to deprioritize or avoid duplicate bookings)
    booked_mentor_ids: Set[int] = {
        b.mentor_id for b in db.query(Booking).filter(Booking.mentee_id == current_user.id).all()
    }

    # 6. Query available mentor offers (excluding the user themselves)
    mentor_query = (
        db.query(UserSkillOffered, User, Skill)
        .join(User, UserSkillOffered.user_id == User.id)
        .join(Skill, UserSkillOffered.skill_id == Skill.id)
        .filter(User.id != current_user.id)
    )
    if not getattr(current_user, "is_test_user", False):
        mentor_query = mentor_query.filter(User.is_test_user == False)
    mentor_offers = mentor_query.all()

    # Count mentors per skill
    mentors_per_skill: Dict[int, int] = {}
    for _, mentor, skill in mentor_offers:
        mentors_per_skill[skill.id] = mentors_per_skill.get(skill.id, 0) + 1

    items: List[RecommendationItem] = []
    seen_mentor_skill: Set[str] = set()

    for offer, mentor, skill in mentor_offers:
        pair_key = f"{mentor.id}_{skill.id}"
        if pair_key in seen_mentor_skill:
            continue
        seen_mentor_skill.add(pair_key)

        # Distance calculation
        distance = None
        if (
            mentor.lat is not None
            and mentor.lng is not None
            and current_user.lat is not None
            and current_user.lng is not None
        ):
            distance = round(haversine(current_user.lat, current_user.lng, mentor.lat, mentor.lng), 1)

        is_learning_goal = (skill.id in wanted_skill_ids) or (skill.id in learning_skills_info)
        same_cat = bool(skill.category and skill.category.lower() in learning_categories)

        # Determine explainable reason
        reason = ""
        explanation_parts = []
        if skill.id in wanted_skill_ids:
            reason = f"Matches your requested goal to learn {skill.name}."
            explanation_parts.append("Direct requested skill")
        elif skill.id in learning_skills_info:
            info = learning_skills_info[skill.id]
            if info["is_done"]:
                reason = f"You completed {skill.name} — practice with mentor {mentor.name}."
                explanation_parts.append("Path completed")
            else:
                reason = f"Recommended because you are learning {skill.name} ({info['percent']}% complete)."
                explanation_parts.append(f"Learning in progress ({info['percent']}%)")
        elif same_cat:
            reason = f"Complements your {skill.category} learning curriculum."
            explanation_parts.append("Complementary category")
        elif distance is not None and distance <= 15.0:
            reason = f"Nearby mentor in your local area ({distance} km)."
            explanation_parts.append(f"{distance} km away")
        else:
            reason = f"Popular skill in {skill.category or 'General'} with top-rated mentor."
            explanation_parts.append("Top-rated mentor")

        if mentor.rating:
            explanation_parts.append(f"Rating {mentor.rating:.1f}★")

        can_learn = skill.id not in certified_skill_ids
        can_teach = (skill.id in certified_skill_ids) or (skill.id in offered_skill_ids)

        match_score = compute_personalized_score(
            distance_km=distance,
            mentor_rating=mentor.rating,
            review_count=mentor.reviews,
            is_learning_goal=is_learning_goal,
            same_category=same_cat,
        )

        items.append(
            RecommendationItem(
                mentor_id=mentor.id,
                mentor_name=mentor.name,
                mentor_profile_image=mentor.avatar_url,
                mentor_rating=mentor.rating,
                mentor_review_count=mentor.reviews or 0,
                mentor_latitude=mentor.lat,
                mentor_longitude=mentor.lng,
                skill_id=skill.id,
                skill_title=skill.name,
                skill_description=f"Learn {skill.name} with {mentor.name}.",
                skill_category=skill.category,
                skill_image_url=f"https://picsum.photos/seed/{skill.id}/400/300",
                match_score=match_score,
                explanation=", ".join(explanation_parts),
                distance_km=distance,
                rating=mentor.rating,
                reason=reason,
                can_learn=can_learn,
                can_teach=can_teach,
                nearby_mentors_count=mentors_per_skill.get(skill.id, 1),
            )
        )

    # Sort deterministically: match_score DESC -> rating DESC -> distance ASC
    items.sort(
        key=lambda r: (
            -r.match_score,
            -(r.mentor_rating or 0.0),
            (r.distance_km if r.distance_km is not None else 99999.0),
        )
    )

    total = len(items)
    start = (page - 1) * limit
    end = start + limit
    paginated_data = [item.model_dump() for item in items[start:end]]

    return {
        "data": paginated_data,
        "page": page,
        "limit": limit,
        "total": total,
    }
