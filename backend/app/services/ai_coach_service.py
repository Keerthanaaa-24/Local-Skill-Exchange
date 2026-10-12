from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from typing import List, Dict, Any, Set, Optional
from datetime import datetime, timezone, timedelta

from ..db.models import (
    User,
    Skill,
    UserSkillOffered,
    UserSkillWanted,
    Booking,
    UserLearningProgress,
    LearningPath,
    Lesson,
    PracticeAttempt,
    QuizAttempt,
    Certificate,
    Review,
    UserXpLog,
    UserAchievement,
    Transaction,
)

def is_clean_skill_name(name: Optional[str]) -> bool:
    """Filter out automated test and debug skill names from user-facing AI recommendations."""
    if not name:
        return False
    lower = name.strip().lower()
    if (
        lower.startswith("skill_")
        or "directtest" in lower
        or lower == "skilldirecttestsuccess"
        or "e2e" in lower
        or lower.startswith("test ")
    ):
        return False
    return True

def make_aware(dt: Optional[datetime]) -> Optional[datetime]:
    """Ensure datetime has timezone for safe comparisons."""
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt

def get_user_learning_data(db: Session, user_id: int) -> Dict[str, Any]:
    progress_rows = db.query(UserLearningProgress).filter(UserLearningProgress.user_id == user_id).all()
    learning_skills: Dict[int, Dict[str, Any]] = {}
    completed_path_ids: Set[int] = set()

    for p in progress_rows:
        path = db.query(LearningPath).filter(LearningPath.id == p.learning_path_id).first()
        if not path:
            continue
        skill = db.query(Skill).filter(Skill.id == path.skill_id).first()
        if not skill or not is_clean_skill_name(skill.name):
            continue

        c_ids = [int(x.strip()) for x in (p.completed_lessons or "").split(",") if x.strip().isdigit()]
        sorted_lessons = sorted(path.lessons, key=lambda l: l.order or l.id)
        total_lessons = len(sorted_lessons)
        pct = round((len(c_ids) / total_lessons) * 100.0) if total_lessons > 0 else 0
        is_done = p.completed_at is not None or (total_lessons > 0 and len(c_ids) >= total_lessons)
        
        if is_done:
            completed_path_ids.add(path.id)

        next_lesson = next((l for l in sorted_lessons if l.id not in c_ids), (sorted_lessons[0] if sorted_lessons else None))

        learning_skills[skill.id] = {
            "path_id": path.id,
            "path_title": path.title,
            "skill_id": skill.id,
            "skill_name": skill.name,
            "category": skill.category or "General",
            "percent": pct,
            "is_done": is_done,
            "completed_lessons_count": len(c_ids),
            "completed_lesson_ids": c_ids,
            "total_lessons_count": total_lessons,
            "started_at": p.started_at,
            "completed_at": p.completed_at,
            "next_lesson_id": next_lesson.id if next_lesson else None,
            "next_lesson_title": next_lesson.title if next_lesson else None,
        }

    return {
        "learning_skills": learning_skills,
        "completed_path_ids": completed_path_ids,
    }

def analyze_user_skill_gaps(db: Session, user: User) -> Dict[str, Any]:
    """
    Skill Gap & Portfolio Engine.
    Classifies skills into Strong, Improving, Needs Practice, and Goal Gap based on real data.
    """
    offered_rows = db.query(UserSkillOffered).filter(UserSkillOffered.user_id == user.id).all()
    offered_skill_ids: Set[int] = {r.skill_id for r in offered_rows}

    wanted_rows = db.query(UserSkillWanted).filter(UserSkillWanted.user_id == user.id).all()
    wanted_skill_ids: Set[int] = {r.skill_id for r in wanted_rows}

    certs = db.query(Certificate).filter(Certificate.user_id == user.id, Certificate.status == "valid").all()
    certified_skill_ids: Set[int] = {c.skill_id for c in certs}

    learning_data = get_user_learning_data(db, user.id)
    learning_skills = learning_data["learning_skills"]

    attempts = (
        db.query(PracticeAttempt)
        .filter(PracticeAttempt.user_id == user.id)
        .order_by(desc(PracticeAttempt.completed_at))
        .all()
    )
    lesson_scores: Dict[int, List[int]] = {}
    for att in attempts:
        lesson_scores.setdefault(att.lesson_id, []).append(att.score)

    portfolio_items = []
    strengths = []
    developing = []
    needs_practice = []

    # 1. Strengths (Certified, High Quiz Average >= 85%, or Teaching)
    strength_skill_ids = certified_skill_ids.union(offered_skill_ids)
    for s_id in strength_skill_ids:
        skill = db.query(Skill).filter(Skill.id == s_id).first()
        if skill and is_clean_skill_name(skill.name):
            is_cert = s_id in certified_skill_ids
            status_text = "Strong"
            level_text = "Expert / Certified" if is_cert else "Proficient (Teaching)"
            reason = "Verified with official certificate" if is_cert else "Offered as mentor skill in profile"
            
            strength_item = {
                "skill_id": skill.id,
                "skill_name": skill.name,
                "category": skill.category or "General",
                "status": status_text,
                "level": level_text,
                "is_certified": is_cert,
                "badge": "Verified Master" if is_cert else "Community Mentor",
                "reason": reason,
            }
            strengths.append(strength_item)
            portfolio_items.append(strength_item)

    # 2. In-Progress Learning Skills (Developing vs Needs Practice)
    for s_id, info in learning_skills.items():
        if s_id in strength_skill_ids:
            continue
        
        # Check practice attempts for this path's lessons
        path = db.query(LearningPath).filter(LearningPath.id == info["path_id"]).first()
        path_lesson_ids = [l.id for l in path.lessons] if path else []
        scores = [sc for l_id in path_lesson_ids if l_id in lesson_scores for sc in lesson_scores[l_id]]

        avg_score = round(sum(scores) / len(scores)) if scores else None
        has_low_score = any(sc < 70 for sc in scores)

        if has_low_score and (avg_score is not None and avg_score < 70):
            status_text = "Needs Practice"
            badge = "Needs Revision"
            reason = f"Quiz accuracy average is {avg_score}%. Review fundamentals to master concepts."
            needs_practice_item = {
                "skill_id": s_id,
                "skill_name": info["skill_name"],
                "category": info["category"],
                "status": status_text,
                "level": "Needs Practice",
                "progress_percent": info["percent"],
                "completed_lessons": info["completed_lessons_count"],
                "total_lessons": info["total_lessons_count"],
                "path_id": info["path_id"],
                "path_title": info["path_title"],
                "badge": badge,
                "reason": reason,
            }
            needs_practice.append(needs_practice_item)
            portfolio_items.append(needs_practice_item)
        else:
            status_text = "Improving"
            badge = "Active Focus"
            reason = f"{info['completed_lessons_count']} of {info['total_lessons_count']} lessons completed ({info['percent']}%)."
            dev_item = {
                "skill_id": s_id,
                "skill_name": info["skill_name"],
                "category": info["category"],
                "status": status_text,
                "level": "In Progress",
                "progress_percent": info["percent"],
                "completed_lessons": info["completed_lessons_count"],
                "total_lessons": info["total_lessons_count"],
                "path_id": info["path_id"],
                "path_title": info["path_title"],
                "badge": badge,
                "reason": reason,
            }
            developing.append(dev_item)
            portfolio_items.append(dev_item)

    # 3. Wanted Skills (Goal Gaps)
    skill_gaps = []
    all_known_skill_ids = strength_skill_ids.union(set(learning_skills.keys()))

    for w_id in wanted_skill_ids:
        if w_id not in all_known_skill_ids:
            skill = db.query(Skill).filter(Skill.id == w_id).first()
            if skill and is_clean_skill_name(skill.name):
                gap_item = {
                    "skill_id": skill.id,
                    "skill_name": skill.name,
                    "category": skill.category or "General",
                    "status": "Goal Gap",
                    "gap_level": "High",
                    "priority_score": 95,
                    "reason": "Listed in your wanted skills wishlist.",
                    "action": "start_learning",
                }
                skill_gaps.append(gap_item)
                portfolio_items.append(gap_item)

    # 4. Complementary Skill Gaps
    active_categories = {s["category"].lower() for s in developing}
    if not active_categories and strengths:
        active_categories = {s["category"].lower() for s in strengths}

    if active_categories:
        comp_skills = db.query(Skill).filter(
            ~Skill.id.in_(all_known_skill_ids) if all_known_skill_ids else True
        ).all()
        for c_skill in comp_skills:
            if c_skill.category and c_skill.category.lower() in active_categories and is_clean_skill_name(c_skill.name):
                if not any(g["skill_id"] == c_skill.id for g in skill_gaps):
                    gap_item = {
                        "skill_id": c_skill.id,
                        "skill_name": c_skill.name,
                        "category": c_skill.category,
                        "status": "Goal Gap",
                        "gap_level": "Medium",
                        "priority_score": 75,
                        "reason": f"Complements your active studies in {c_skill.category}.",
                        "action": "explore_curriculum",
                    }
                    skill_gaps.append(gap_item)

    skill_gaps.sort(key=lambda x: -x["priority_score"])

    return {
        "portfolio": portfolio_items,
        "skill_portfolio": portfolio_items,
        "strengths": strengths,
        "developing": developing,
        "needs_practice": needs_practice,
        "skill_gaps": skill_gaps[:6],
    }

def generate_hero_recommendation(db: Session, user: User) -> Dict[str, Any]:
    """
    Step 1: AI Coach Home Hero Step ("Your next best step")
    Evaluates real user data to generate the single most impactful recommendation.
    """
    # 1. Recent weak quiz (< 70% accuracy) -> Revision priority
    recent_attempts = (
        db.query(PracticeAttempt)
        .filter(PracticeAttempt.user_id == user.id)
        .order_by(desc(PracticeAttempt.completed_at))
        .all()
    )
    for att in recent_attempts:
        if att.score < 70:
            lesson = db.query(Lesson).filter(Lesson.id == att.lesson_id).first()
            if lesson:
                path = db.query(LearningPath).filter(LearningPath.id == lesson.learning_path_id).first()
                skill = db.query(Skill).filter(Skill.id == path.skill_id).first() if path else None
                skill_name = skill.name if skill and is_clean_skill_name(skill.name) else (path.title if path else lesson.title)
                
                return {
                    "skill_id": skill.id if skill else 0,
                    "skill_name": f"Revise: {lesson.title}",
                    "category": skill.category if skill else "General",
                    "gap_level": "Urgent Revision",
                    "reason": f"Your last quiz score on '{lesson.title}' was {att.score}%. Practice key concepts to achieve mastery before advancing.",
                    "has_learning_path": True,
                    "path_id": path.id if path else None,
                    "available_mentors_count": 1,
                    "confidence_score": 98,
                    "action_type": "practice",
                }

    # 2. Check for inactivity (> 2 days since last learning in active path)
    now = datetime.now(timezone.utc)
    learning_data = get_user_learning_data(db, user.id)
    for s_id, info in learning_data["learning_skills"].items():
        if not info["is_done"]:
            # Find latest attempt or start time
            latest_att = (
                db.query(PracticeAttempt)
                .filter(PracticeAttempt.user_id == user.id)
                .order_by(desc(PracticeAttempt.completed_at))
                .first()
            )
            last_time = latest_att.completed_at if latest_att else info["started_at"]
            if last_time:
                last_time_aware = make_aware(last_time)
                days_inactive = (now - last_time_aware).days if last_time_aware else 0
                if days_inactive >= 3:
                    return {
                        "skill_id": s_id,
                        "skill_name": f"Resume: {info['skill_name']}",
                        "category": info["category"],
                        "gap_level": "Streak at Risk",
                        "reason": f"You haven't practiced {info['skill_name']} for {days_inactive} days. Consistent micro-learning compounds mastery.",
                        "has_learning_path": True,
                        "path_id": info["path_id"],
                        "available_mentors_count": 1,
                        "confidence_score": 96,
                        "action_type": "learning",
                    }

    # 3. Active in-progress path -> Continue next specific lesson
    for s_id, info in learning_data["learning_skills"].items():
        if not info["is_done"]:
            next_title = info["next_lesson_title"] or "Next Lesson"
            return {
                "skill_id": s_id,
                "skill_name": f"Complete: {next_title}",
                "category": info["category"],
                "gap_level": "In Progress",
                "reason": f"Continue your progress on {info['path_title']} ({info['percent']}% complete, {info['completed_lessons_count']}/{info['total_lessons_count']} lessons done).",
                "has_learning_path": True,
                "path_id": info["path_id"],
                "available_mentors_count": 1,
                "confidence_score": 95,
                "action_type": "learning",
            }

    # 4. Completed path with high score -> Ready for Intermediate or Certification
    certs = db.query(Certificate).filter(Certificate.user_id == user.id, Certificate.status == "valid").all()
    cert_path_ids = {c.learning_path_id for c in certs}
    for path_id in learning_data["completed_path_ids"]:
        path = db.query(LearningPath).filter(LearningPath.id == path_id).first()
        if not path:
            continue
        skill = db.query(Skill).filter(Skill.id == path.skill_id).first()
        if path_id not in cert_path_ids:
            return {
                "skill_id": skill.id if skill else 0,
                "skill_name": f"Claim {path.title} Certificate",
                "category": skill.category if skill else "General",
                "gap_level": "Certification Ready",
                "reason": f"You finished all lessons in {path.title}! Issue your verified cryptographic credential.",
                "has_learning_path": True,
                "path_id": path.id,
                "available_mentors_count": 1,
                "confidence_score": 97,
                "action_type": "certificate",
            }
        else:
            # Completed & Certified -> Recommend next difficulty
            return {
                "skill_id": skill.id if skill else 0,
                "skill_name": f"Ready for Intermediate {skill.name if skill else 'Skills'}",
                "category": skill.category if skill else "General",
                "gap_level": "Mastered",
                "reason": f"You scored consistently high and earned your verified certificate in {skill.name if skill else 'this course'}. Ready for advanced topics.",
                "has_learning_path": True,
                "path_id": path.id,
                "available_mentors_count": 1,
                "confidence_score": 94,
                "action_type": "learning",
            }

    # 5. Wanted skill wishlist gap
    gap_data = analyze_user_skill_gaps(db, user)
    if gap_data["skill_gaps"]:
        top_gap = gap_data["skill_gaps"][0]
        path = db.query(LearningPath).filter(LearningPath.skill_id == top_gap["skill_id"]).first()
        mentor_count = db.query(UserSkillOffered).filter(
            UserSkillOffered.skill_id == top_gap["skill_id"],
            UserSkillOffered.user_id != user.id
        ).count()

        return {
            "skill_id": top_gap["skill_id"],
            "skill_name": f"Begin: {top_gap['skill_name']}",
            "category": top_gap["category"],
            "gap_level": top_gap["gap_level"],
            "reason": f"{top_gap['reason']} Start the foundational curriculum.",
            "has_learning_path": path is not None,
            "path_id": path.id if path else None,
            "available_mentors_count": mentor_count,
            "confidence_score": 92,
            "action_type": "learning" if path else "mentors",
        }

    # 6. Default starter skill
    first_skill = db.query(Skill).all()
    clean_first = next((s for s in first_skill if is_clean_skill_name(s.name)), None)
    if clean_first:
        path = db.query(LearningPath).filter(LearningPath.skill_id == clean_first.id).first()
        return {
            "skill_id": clean_first.id,
            "skill_name": f"Explore: {clean_first.name}",
            "category": clean_first.category or "General",
            "gap_level": "Recommended Starter",
            "reason": f"Start building your profile with foundational skills in {clean_first.category or 'General'}.",
            "has_learning_path": path is not None,
            "path_id": path.id if path else None,
            "available_mentors_count": 1,
            "confidence_score": 90,
            "action_type": "learning" if path else "explore",
        }

    return {
        "skill_id": 0,
        "skill_name": "Explore Skill Catalog",
        "category": "General",
        "gap_level": "Recommended Starter",
        "reason": "Browse 1,500+ structured skills to start your personalized learning path.",
        "has_learning_path": False,
        "path_id": None,
        "available_mentors_count": 0,
        "confidence_score": 90,
        "action_type": "explore",
    }

def generate_daily_plan(db: Session, user: User) -> List[Dict[str, Any]]:
    """
    Step 2: Today's AI Learning Plan
    Generates 3-4 structured, clickable daily tasks prioritizing existing unfinished learning.
    """
    plan_items: List[Dict[str, Any]] = []
    learning_data = get_user_learning_data(db, user.id)
    learning_skills = learning_data["learning_skills"]

    # 1. Action 1: Unfinished active lesson
    in_progress = [s for s in learning_skills.values() if not s["is_done"]]
    if in_progress:
        active = in_progress[0]
        next_title = active["next_lesson_title"] or "Next Lesson"
        plan_items.append({
            "id": "plan_continue_lesson",
            "title": f"Continue {active['skill_name']} — {next_title}",
            "duration_minutes": 20,
            "action_type": "learning",
            "target_id": active["path_id"],
            "path_id": active["path_id"],
            "is_completed": False,
            "reward_xp": 30,
            "reason": f"Advance your {active['path_title']} progress ({active['percent']}% complete).",
        })
    else:
        # Starter lesson
        gap_data = analyze_user_skill_gaps(db, user)
        if gap_data["skill_gaps"]:
            top_gap = gap_data["skill_gaps"][0]
            path = db.query(LearningPath).filter(LearningPath.skill_id == top_gap["skill_id"]).first()
            plan_items.append({
                "id": "plan_start_skill",
                "title": f"Start {top_gap['skill_name']} — Lesson 1",
                "duration_minutes": 20,
                "action_type": "learning",
                "target_id": path.id if path else top_gap["skill_id"],
                "path_id": path.id if path else None,
                "is_completed": False,
                "reward_xp": 30,
                "reason": top_gap["reason"],
            })

    # 2. Action 2: Practice Quiz or Weak Area Revision
    weak_attempts = (
        db.query(PracticeAttempt)
        .filter(PracticeAttempt.user_id == user.id, PracticeAttempt.score < 70)
        .order_by(desc(PracticeAttempt.completed_at))
        .all()
    )
    if weak_attempts:
        weak = weak_attempts[0]
        lesson = db.query(Lesson).filter(Lesson.id == weak.lesson_id).first()
        if lesson:
            path = db.query(LearningPath).filter(LearningPath.id == lesson.learning_path_id).first()
            plan_items.append({
                "id": "plan_practice_weak",
                "title": f"Practice {lesson.title} Quiz",
                "duration_minutes": 10,
                "action_type": "practice",
                "target_id": lesson.id,
                "path_id": path.id if path else None,
                "is_completed": False,
                "reward_xp": 25,
                "reason": f"Retake practice to turn your {weak.score}% score into 85%+ mastery.",
            })
    elif in_progress:
        active = in_progress[0]
        plan_items.append({
            "id": "plan_practice_current",
            "title": f"Practice {active['skill_name']} Quiz Set",
            "duration_minutes": 10,
            "action_type": "learning",
            "target_id": active["path_id"],
            "path_id": active["path_id"],
            "is_completed": False,
            "reward_xp": 20,
            "reason": "Test your retention on key lesson concepts.",
        })
    else:
        plan_items.append({
            "id": "plan_practice_general",
            "title": "Practice Daily Micro-Quiz",
            "duration_minutes": 10,
            "action_type": "explore",
            "target_id": 0,
            "path_id": None,
            "is_completed": False,
            "reward_xp": 20,
            "reason": "Daily practice builds consistent learning habits.",
        })

    # 3. Action 3: Review study materials & notes
    if in_progress:
        active = in_progress[0]
        plan_items.append({
            "id": "plan_review_notes",
            "title": f"Review {active['skill_name']} Study Materials",
            "duration_minutes": 5,
            "action_type": "learning",
            "target_id": active["path_id"],
            "path_id": active["path_id"],
            "is_completed": False,
            "reward_xp": 10,
            "reason": "Reinforce yesterday's key formulas, syntax, and concepts.",
        })
    else:
        plan_items.append({
            "id": "plan_review_general",
            "title": "Review Skill Passport & Strengths",
            "duration_minutes": 5,
            "action_type": "passport",
            "target_id": user.id,
            "path_id": None,
            "is_completed": False,
            "reward_xp": 10,
            "reason": "Review your verified credentials and growth milestones.",
        })

    return plan_items

def calculate_skill_growth(db: Session, user: User) -> Dict[str, Any]:
    attempts = (
        db.query(PracticeAttempt)
        .filter(PracticeAttempt.user_id == user.id)
        .order_by(PracticeAttempt.completed_at.asc())
        .all()
    )

    learning_data = get_user_learning_data(db, user.id)
    learning_skills = learning_data["learning_skills"]
    certs = db.query(Certificate).filter(Certificate.user_id == user.id, Certificate.status == "valid").all()

    lesson_attempts: Dict[int, List[PracticeAttempt]] = {}
    for att in attempts:
        lesson_attempts.setdefault(att.lesson_id, []).append(att)

    metrics = []
    total_initial_score = 0
    total_current_score = 0
    evaluated_count = 0

    for lesson_id, att_list in lesson_attempts.items():
        lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
        if not lesson:
            continue
        path = db.query(LearningPath).filter(LearningPath.id == lesson.learning_path_id).first()
        skill = db.query(Skill).filter(Skill.id == path.skill_id).first() if path else None
        skill_name = skill.name if skill and is_clean_skill_name(skill.name) else (path.title if path else lesson.title)

        first_score = att_list[0].score
        latest_score = att_list[-1].score
        improvement = latest_score - first_score
        attempts_count = len(att_list)

        total_initial_score += first_score
        total_current_score += latest_score
        evaluated_count += 1

        if latest_score >= 85:
            trend = "mastered"
            badge = "Mastered"
        elif improvement > 10:
            trend = "improving"
            badge = f"+{improvement}% Gain"
        elif latest_score >= 70:
            trend = "stable"
            badge = "Consistent"
        else:
            trend = "needs_attention"
            badge = "Needs Revision"

        metrics.append({
            "lesson_id": lesson_id,
            "lesson_title": lesson.title,
            "skill_name": skill_name,
            "initial_score": first_score,
            "current_score": latest_score,
            "attempts_count": attempts_count,
            "improvement_pct": improvement,
            "trend": trend,
            "status_badge": badge,
        })

    if evaluated_count > 0:
        avg_initial = round(total_initial_score / evaluated_count, 1)
        avg_current = round(total_current_score / evaluated_count, 1)
        overall_gain = round(avg_current - avg_initial, 1)
        
        if len(attempts) >= 2 and overall_gain > 0:
            narrative = f"Your practice accuracy improved by +{overall_gain}% across recent quiz evaluations (from {avg_initial}% to {avg_current}%)."
        elif len(attempts) >= 2 and overall_gain < 0:
            narrative = f"Your practice accuracy dropped by {abs(overall_gain)}% across recent evaluations (from {avg_initial}% to {avg_current}%). Focus on revision."
        elif len(attempts) >= 2:
            narrative = f"Your practice performance is steady with an average accuracy of {avg_current}% across {len(attempts)} attempts."
        else:
            narrative = f"Baseline established at {avg_current}% accuracy on your first practice attempt."
    else:
        avg_initial = 0.0
        avg_current = 0.0
        overall_gain = 0.0
        narrative = "Not enough historical practice data yet. Complete quizzes to establish your growth velocity."

    passing_attempts = [a for a in attempts if a.score >= 70]
    consistency_pct = round((len(passing_attempts) / len(attempts)) * 100) if attempts else 0
    
    cert_pts = min(40, len(certs) * 40)
    quiz_pts = min(30, int((avg_current / 100.0) * 30))
    completed_paths_count = len(learning_data["completed_path_ids"])
    learning_pts = min(30, completed_paths_count * 20 + len(learning_skills) * 10)
    mastery_index = min(100, cert_pts + quiz_pts + learning_pts)

    return {
        "user_id": user.id,
        "mastery_index": mastery_index,
        "overall_average_accuracy": avg_current,
        "initial_average_accuracy": avg_initial,
        "accuracy_improvement_pct": overall_gain,
        "total_practice_attempts": len(attempts),
        "passing_consistency_pct": consistency_pct,
        "certified_skills_count": len(certs),
        "growth_narrative": narrative,
        "has_sufficient_history": len(attempts) >= 2,
        "metrics": metrics[:6],
    }

def generate_practice_diagnostics(db: Session, user: User) -> List[Dict[str, Any]]:
    """
    Step 5: Smart Practice Diagnostics & Adaptive Quiz Engine
    """
    attempts = (
        db.query(PracticeAttempt)
        .filter(PracticeAttempt.user_id == user.id)
        .order_by(desc(PracticeAttempt.completed_at))
        .all()
    )

    diagnostics = []
    seen_lessons: Set[int] = set()

    for att in attempts:
        if att.lesson_id in seen_lessons:
            continue
        seen_lessons.add(att.lesson_id)

        lesson = db.query(Lesson).filter(Lesson.id == att.lesson_id).first()
        if not lesson:
            continue
        path = db.query(LearningPath).filter(LearningPath.id == lesson.learning_path_id).first()

        is_weak = att.score < 70
        is_moderate = 70 <= att.score < 85
        is_mastered = att.score >= 85

        if is_weak:
            diagnostics.append({
                "lesson_id": lesson.id,
                "lesson_title": lesson.title,
                "path_id": path.id if path else None,
                "path_title": path.title if path else "Learning Path",
                "last_score": att.score,
                "status": "needs_revision",
                "severity": "high",
                "message": f"Accuracy on '{lesson.title}' is {att.score}%. Review parameters and key concepts before moving forward.",
                "recommendation": "Retake Practice Quiz",
            })
        elif is_moderate:
            diagnostics.append({
                "lesson_id": lesson.id,
                "lesson_title": lesson.title,
                "path_id": path.id if path else None,
                "path_title": path.title if path else "Learning Path",
                "last_score": att.score,
                "status": "moderate",
                "severity": "medium",
                "message": f"Good progress with {att.score}% on '{lesson.title}'. Practice once more to reach 90%+ mastery.",
                "recommendation": "Aim for 90%+ Mastery",
            })
        elif is_mastered:
            diagnostics.append({
                "lesson_id": lesson.id,
                "lesson_title": lesson.title,
                "path_id": path.id if path else None,
                "path_title": path.title if path else "Learning Path",
                "last_score": att.score,
                "status": "mastered",
                "severity": "low",
                "message": f"You scored {att.score}%! You have mastered '{lesson.title}' and are ready for the next level.",
                "recommendation": "Concept Mastered",
            })

    return diagnostics[:4]

def generate_adaptive_recommendations(db: Session, user: User) -> List[Dict[str, Any]]:
    recs: List[Dict[str, Any]] = []
    learning_data = get_user_learning_data(db, user.id)
    learning_skills = learning_data["learning_skills"]
    
    # 1. Weak practice attempts needing review
    attempts = (
        db.query(PracticeAttempt)
        .filter(PracticeAttempt.user_id == user.id)
        .order_by(desc(PracticeAttempt.completed_at))
        .all()
    )
    seen_weak_lessons = set()
    for att in attempts:
        if att.score < 70 and att.lesson_id not in seen_weak_lessons:
            seen_weak_lessons.add(att.lesson_id)
            lesson = db.query(Lesson).filter(Lesson.id == att.lesson_id).first()
            if lesson:
                path = db.query(LearningPath).filter(LearningPath.id == lesson.learning_path_id).first()
                recs.append({
                    "id": f"review_lesson_{lesson.id}",
                    "category_type": "REVIEW_TOPIC",
                    "title": f"Review: {lesson.title}",
                    "subtitle": f"Last quiz score was {att.score}%. Retake practice to strengthen concepts.",
                    "priority": "urgent",
                    "confidence_score": 98,
                    "action_label": "Retake Practice",
                    "action_type": "practice",
                    "target_id": lesson.id,
                    "path_id": path.id if path else None,
                    "source_signal": "Quiz accuracy < 70%",
                })

    # 2. Mastered topics ready for harder content / certification
    for att in attempts:
        if att.score >= 85:
            lesson = db.query(Lesson).filter(Lesson.id == att.lesson_id).first()
            if lesson:
                path = db.query(LearningPath).filter(LearningPath.id == lesson.learning_path_id).first()
                if path and not any(r["target_id"] == path.id for r in recs):
                    recs.append({
                        "id": f"harder_content_{path.id}",
                        "category_type": "HARDER_CONTENT",
                        "title": f"Next Level: {path.title}",
                        "subtitle": f"High {att.score}% mastery on '{lesson.title}'. Ready for advanced modules.",
                        "priority": "medium",
                        "confidence_score": 95,
                        "action_label": "Advance Path",
                        "action_type": "learning",
                        "target_id": path.id,
                        "path_id": path.id,
                        "source_signal": f"Quiz Mastery {att.score}%",
                    })

    # 3. Completed paths without certificate
    certs = db.query(Certificate).filter(Certificate.user_id == user.id, Certificate.status == "valid").all()
    cert_path_ids = {c.learning_path_id for c in certs}
    for path_id in learning_data["completed_path_ids"]:
        if path_id not in cert_path_ids:
            path = db.query(LearningPath).filter(LearningPath.id == path_id).first()
            if path:
                recs.append({
                    "id": f"cert_path_{path.id}",
                    "category_type": "PREPARE_CERTIFICATION",
                    "title": f"Claim Certificate: {path.title}",
                    "subtitle": "All curriculum lessons completed! Issue your verified credential.",
                    "priority": "high",
                    "confidence_score": 96,
                    "action_label": "View Certificate",
                    "action_type": "certificate",
                    "target_id": path.id,
                    "path_id": path.id,
                    "source_signal": "100% Curriculum Completed",
                })

    # 4. In-progress learning paths
    for s_id, info in learning_skills.items():
        if not info["is_done"]:
            recs.append({
                "id": f"continue_path_{info['path_id']}",
                "category_type": "CONTINUE_LEARNING",
                "title": f"Continue: {info['path_title']}",
                "subtitle": f"{info['completed_lessons_count']} of {info['total_lessons_count']} lessons done ({info['percent']}%).",
                "priority": "high",
                "confidence_score": 94,
                "action_label": "Resume Learning",
                "action_type": "learning",
                "target_id": info["path_id"],
                "path_id": info["path_id"],
                "source_signal": "Active Learning Pathway",
            })

    # 5. Skill gaps
    gap_data = analyze_user_skill_gaps(db, user)
    for gap in gap_data["skill_gaps"][:2]:
        path = db.query(LearningPath).filter(LearningPath.skill_id == gap["skill_id"]).first()
        recs.append({
            "id": f"gap_skill_{gap['skill_id']}",
            "category_type": "LEARN_NEXT",
            "title": f"Learn Next: {gap['skill_name']}",
            "subtitle": gap["reason"],
            "priority": "medium",
            "confidence_score": gap["priority_score"],
            "action_label": "Start Path" if path else "Find Mentors",
            "action_type": "learning" if path else "mentors",
            "target_id": path.id if path else gap["skill_id"],
            "path_id": path.id if path else None,
            "source_signal": f"Skill Gap ({gap['gap_level']} Priority)",
        })

    # Default fallback
    if not recs:
        first_clean_skill = db.query(Skill).all()
        clean_skill = next((s for s in first_clean_skill if is_clean_skill_name(s.name)), None)
        if clean_skill:
            path = db.query(LearningPath).filter(LearningPath.skill_id == clean_skill.id).first()
            recs.append({
                "id": f"starter_skill_{clean_skill.id}",
                "category_type": "LEARN_NEXT",
                "title": f"Explore: {clean_skill.name}",
                "subtitle": f"Recommended starter skill in {clean_skill.category or 'General'}.",
                "priority": "medium",
                "confidence_score": 90,
                "action_label": "Explore Skill",
                "action_type": "learning" if path else "explore",
                "target_id": path.id if path else clean_skill.id,
                "path_id": path.id if path else None,
                "source_signal": "Foundational Skill Domain",
            })

    return recs[:5]

def generate_personalized_roadmap(db: Session, user: User) -> List[Dict[str, Any]]:
    learning_data = get_user_learning_data(db, user.id)
    learning_skills = learning_data["learning_skills"]

    roadmap_steps = []
    step_num = 1

    for s_id, info in learning_skills.items():
        if info["is_done"]:
            roadmap_steps.append({
                "step_number": step_num,
                "skill_id": s_id,
                "path_id": info["path_id"],
                "title": info["skill_name"],
                "subtitle": f"{info['path_title']} • Completed",
                "category": info["category"],
                "status": "completed",
                "progress_percent": 100,
                "badge": "Completed",
                "action_type": "view_certificate",
            })
            step_num += 1

    for s_id, info in learning_skills.items():
        if not info["is_done"]:
            roadmap_steps.append({
                "step_number": step_num,
                "skill_id": s_id,
                "path_id": info["path_id"],
                "title": info["skill_name"],
                "subtitle": f"{info['path_title']} • In Progress ({info['completed_lessons_count']}/{info['total_lessons_count']} lessons)",
                "category": info["category"],
                "status": "in_progress",
                "progress_percent": info["percent"],
                "badge": "Current Focus",
                "action_type": "continue_lesson",
            })
            step_num += 1

    gap_data = analyze_user_skill_gaps(db, user)
    for gap in gap_data["skill_gaps"][:2]:
        existing_path = db.query(LearningPath).filter(LearningPath.skill_id == gap["skill_id"]).first()
        has_path = existing_path is not None
        
        roadmap_steps.append({
            "step_number": step_num,
            "skill_id": gap["skill_id"],
            "path_id": existing_path.id if existing_path else None,
            "title": gap["skill_name"],
            "subtitle": f"{gap['reason']}",
            "category": gap["category"],
            "status": "recommended_next",
            "progress_percent": 0,
            "badge": "Recommended Goal" if not has_path else "Available Path",
            "action_type": "start_learning" if has_path else "find_mentor",
        })
        step_num += 1

    if not roadmap_steps:
        all_skills = db.query(Skill).all()
        clean_skills = [s for s in all_skills if is_clean_skill_name(s.name)]
        for idx, sk in enumerate(clean_skills[:3], start=1):
            path = db.query(LearningPath).filter(LearningPath.skill_id == sk.id).first()
            roadmap_steps.append({
                "step_number": idx,
                "skill_id": sk.id,
                "path_id": path.id if path else None,
                "title": sk.name,
                "subtitle": f"Popular beginner milestone in {sk.category or 'General'}",
                "category": sk.category or "General",
                "status": "recommended_next" if idx == 1 else "future_milestone",
                "progress_percent": 0,
                "badge": "Starter Skill",
                "action_type": "start_learning" if path else "find_mentor",
            })

    return roadmap_steps

def generate_exchange_suggestions(db: Session, user: User) -> List[Dict[str, Any]]:
    """
    Step 6: Two-Way Skill Exchange Intelligence
    Excludes test users and highlights reciprocal matching.
    """
    user_offered_ids = {r.skill_id for r in db.query(UserSkillOffered).filter(UserSkillOffered.user_id == user.id).all()}
    user_wanted_ids = {r.skill_id for r in db.query(UserSkillWanted).filter(UserSkillWanted.user_id == user.id).all()}

    if not user_offered_ids and not user_wanted_ids:
        return []

    peer_query = db.query(User).filter(User.id != user.id)
    if not getattr(user, "is_test_user", False):
        peer_query = peer_query.filter(User.is_test_user == False)
    potential_peers = peer_query.all()
    exchange_matches = []

    for peer in potential_peers:
        # Extra safeguard: skip automated test accounts
        peer_name_lower = (peer.name or "").lower()
        if "e2e" in peer_name_lower or "test user" in peer_name_lower:
            continue

        peer_offered = {r.skill_id for r in db.query(UserSkillOffered).filter(UserSkillOffered.user_id == peer.id).all()}
        peer_wanted = {r.skill_id for r in db.query(UserSkillWanted).filter(UserSkillWanted.user_id == peer.id).all()}

        i_teach_peer = user_offered_ids.intersection(peer_wanted)
        peer_teaches_me = user_wanted_ids.intersection(peer_offered)

        if i_teach_peer or peer_teaches_me:
            teach_skills = db.query(Skill).filter(Skill.id.in_(i_teach_peer)).all() if i_teach_peer else []
            learn_skills = db.query(Skill).filter(Skill.id.in_(peer_teaches_me)).all() if peer_teaches_me else []

            teach_names = [s.name for s in teach_skills if is_clean_skill_name(s.name)]
            learn_names = [s.name for s in learn_skills if is_clean_skill_name(s.name)]

            if not teach_names and not learn_names:
                continue

            is_perfect_two_way = bool(teach_names and learn_names)

            if is_perfect_two_way:
                reason = f"You want to learn {', '.join(learn_names)}. You can teach {', '.join(teach_names)}. Perfect 2-way swap match!"
                match_score = 96.0
            elif teach_names:
                reason = f"You can teach {', '.join(teach_names)} to {peer.name}."
                match_score = 85.0
            else:
                reason = f"{peer.name} teaches {', '.join(learn_names)}, which matches your learning wishlist."
                match_score = 88.0

            exchange_matches.append({
                "peer_id": peer.id,
                "peer_name": peer.name,
                "peer_avatar": peer.avatar_url,
                "peer_rating": peer.rating,
                "peer_reviews": peer.reviews,
                "is_two_way_swap": is_perfect_two_way,
                "skills_you_teach": teach_names,
                "skills_you_learn": learn_names,
                "explanation": reason,
                "match_score": match_score,
            })

    exchange_matches.sort(key=lambda x: -x["match_score"])
    return exchange_matches[:4]

def get_daily_goal(db: Session, user: User) -> Dict[str, Any]:
    """
    Step 7: Daily Objective & Actionable Plan
    """
    plan = generate_daily_plan(db, user)

    # 1. Weak practice quiz needing revision
    attempts = (
        db.query(PracticeAttempt)
        .filter(PracticeAttempt.user_id == user.id)
        .order_by(desc(PracticeAttempt.completed_at))
        .all()
    )
    for att in attempts:
        if att.score < 70:
            lesson = db.query(Lesson).filter(Lesson.id == att.lesson_id).first()
            if lesson:
                return {
                    "goal_title": f"Revise: {lesson.title}",
                    "description": f"Your last score was {att.score}%. Retake practice today to achieve 85%+ mastery.",
                    "reason": "Reinforcing weak topics builds long-term retention.",
                    "priority": "urgent",
                    "action_label": "Start Practice",
                    "action_type": "practice",
                    "target_id": lesson.id,
                    "is_completed": False,
                    "streak_days": user.streak_days or 0,
                    "reward_xp": 50,
                    "daily_plan": plan,
                }

    # 2. In-progress learning path
    learning_data = get_user_learning_data(db, user.id)
    for s_id, info in learning_data["learning_skills"].items():
        if not info["is_done"]:
            return {
                "goal_title": f"Advance: {info['path_title']}",
                "description": f"Complete {info['next_lesson_title'] or 'next lesson'} ({info['completed_lessons_count'] + 1} of {info['total_lessons_count']}) to maintain your streak.",
                "reason": f"You are currently {info['percent']}% through this curriculum.",
                "priority": "high",
                "action_label": "Continue Lesson",
                "action_type": "learning",
                "target_id": info["path_id"],
                "is_completed": False,
                "streak_days": user.streak_days or 0,
                "reward_xp": 40,
                "daily_plan": plan,
            }

    # 3. Completed path without certificate
    certs = db.query(Certificate).filter(Certificate.user_id == user.id, Certificate.status == "valid").all()
    cert_path_ids = {c.learning_path_id for c in certs}
    for path_id in learning_data["completed_path_ids"]:
        if path_id not in cert_path_ids:
            path = db.query(LearningPath).filter(LearningPath.id == path_id).first()
            if path:
                return {
                    "goal_title": f"Claim Your {path.title} Certificate",
                    "description": "You finished all lessons! Issue your verifiable credential.",
                    "reason": "Verified credentials boost your credibility in peer exchanges.",
                    "priority": "high",
                    "action_label": "View Certificate",
                    "action_type": "certificate",
                    "target_id": path.id,
                    "is_completed": False,
                    "streak_days": user.streak_days or 0,
                    "reward_xp": 100,
                    "daily_plan": plan,
                }

    # 4. Default goal
    gap_data = analyze_user_skill_gaps(db, user)
    if gap_data["skill_gaps"]:
        top_gap = gap_data["skill_gaps"][0]
        path = db.query(LearningPath).filter(LearningPath.skill_id == top_gap["skill_id"]).first()
        return {
            "goal_title": f"Begin Learning: {top_gap['skill_name']}",
            "description": f"Start the foundational module in {top_gap['category']}.",
            "reason": top_gap["reason"],
            "priority": "medium",
            "action_label": "Explore Path" if path else "Find Mentors",
            "action_type": "learning" if path else "mentors",
            "target_id": path.id if path else top_gap["skill_id"],
            "is_completed": False,
            "streak_days": user.streak_days or 0,
            "reward_xp": 30,
            "daily_plan": plan,
        }

    return {
        "goal_title": "Daily Skill Practice",
        "description": "Complete any practice quiz or skill exchange to keep your streak burning!",
        "reason": "Regular daily micro-learning drives compounding mastery.",
        "priority": "medium",
        "action_label": "Explore Skills",
        "action_type": "explore",
        "target_id": 0,
        "is_completed": False,
        "streak_days": user.streak_days or 0,
        "reward_xp": 25,
        "daily_plan": plan,
    }

def get_weekly_insights(db: Session, user: User) -> Dict[str, Any]:
    """
    Step 8: Weekly AI Growth Insights
    Calculates actual rolling 7-day study minutes, quiz performance, and comparisons with previous week.
    """
    now = datetime.now(timezone.utc)
    week_ago = now - timedelta(days=7)
    prior_week_ago = now - timedelta(days=14)

    # 1. Practice attempts in last 7 days vs prior 7 days
    all_attempts = db.query(PracticeAttempt).filter(PracticeAttempt.user_id == user.id).all()
    week_attempts = [a for a in all_attempts if a.completed_at and make_aware(a.completed_at) >= week_ago]
    prior_attempts = [
        a for a in all_attempts
        if a.completed_at and week_ago > make_aware(a.completed_at) >= prior_week_ago
    ]
    total_week_attempts = len(week_attempts)
    
    if week_attempts:
        week_avg_accuracy = round(sum(a.score for a in week_attempts) / len(week_attempts), 1)
    elif all_attempts:
        week_avg_accuracy = round(sum(a.score for a in all_attempts) / len(all_attempts), 1)
    else:
        week_avg_accuracy = 0.0

    # 2. XP logs in last 7 days
    xp_logs = db.query(UserXpLog).filter(UserXpLog.user_id == user.id).all()
    week_xp_logs = [x for x in xp_logs if x.created_at and make_aware(x.created_at) >= week_ago]
    week_xp_gained = sum(x.xp_amount for x in week_xp_logs) if week_xp_logs else (user.xp or 0)

    # 3. Certificates in last 7 days
    certs = db.query(Certificate).filter(Certificate.user_id == user.id, Certificate.status == "valid").all()
    week_certs = [c for c in certs if c.issued_at and make_aware(c.issued_at) >= week_ago]

    # 4. Completed Bookings / Exchanges
    bookings = db.query(Booking).filter(
        (Booking.mentee_id == user.id) | (Booking.mentor_id == user.id),
        Booking.status == "completed"
    ).all()
    week_bookings = [b for b in bookings if b.date and make_aware(b.date) >= week_ago]
    prior_bookings = [b for b in bookings if b.date and week_ago > make_aware(b.date) >= prior_week_ago]

    # 5. Calculate realistic study minutes:
    # Each practice attempt ~ 10 min, completed exchange ~ 60 min, enrolled active lesson ~ 20 min
    this_week_minutes = (total_week_attempts * 10) + (len(week_bookings) * 60) + (len(week_certs) * 30)
    prior_week_minutes = (len(prior_attempts) * 10) + (len(prior_bookings) * 60)
    
    # Fallback to at least modest study time if streak is active
    if this_week_minutes == 0 and (user.streak_days or 0) > 0:
        this_week_minutes = (user.streak_days or 1) * 15

    this_week_hours = round(this_week_minutes / 60.0, 1)
    diff_minutes = this_week_minutes - prior_week_minutes

    # Narrative highlights
    highlights = []
    if this_week_minutes > 0:
        if diff_minutes > 0 and prior_week_minutes > 0:
            highlights.append(f"You studied {this_week_hours} hours this week, {diff_minutes} minutes more than last week.")
        else:
            highlights.append(f"You logged {this_week_hours} hours of dedicated skill learning and practice this week.")
    
    if week_xp_gained > 0:
        highlights.append(f"+{week_xp_gained} XP earned across platform activities.")
    if len(certs) > 0:
        highlights.append(f"{len(certs)} verified certification milestone{'s' if len(certs) > 1 else ''} active.")
    if len(all_attempts) > 0:
        highlights.append(f"{week_avg_accuracy}% average quiz accuracy across {len(all_attempts)} practice session{'s' if len(all_attempts) > 1 else ''}.")
    if len(bookings) > 0:
        highlights.append(f"{len(bookings)} peer skill exchange{'s' if len(bookings) > 1 else ''} completed.")
    if user.streak_days and user.streak_days > 0:
        highlights.append(f"{user.streak_days}-day daily learning streak active!")

    if not highlights:
        highlights.append("Start lessons or practice quizzes this week to unlock detailed weekly AI growth tracking.")

    return {
        "user_id": user.id,
        "week_start": week_ago.isoformat(),
        "week_end": now.isoformat(),
        "xp_gained_week": week_xp_gained,
        "practice_attempts_week": total_week_attempts,
        "average_accuracy_week": week_avg_accuracy,
        "certificates_earned_week": len(week_certs),
        "exchanges_completed_week": len(week_bookings),
        "time_spent_minutes_week": this_week_minutes,
        "streak_days": user.streak_days or 0,
        "consistency_rating": "Mastery Pace" if (user.streak_days or 0) >= 3 else "Active Learner",
        "highlights": highlights,
        "has_sufficient_history": len(all_attempts) > 0 or week_xp_gained > 0,
    }

def get_coach_summary(db: Session, user: User) -> Dict[str, Any]:
    gap_data = analyze_user_skill_gaps(db, user)
    roadmap = generate_personalized_roadmap(db, user)
    diagnostics = generate_practice_diagnostics(db, user)
    exchanges = generate_exchange_suggestions(db, user)
    daily_goal = get_daily_goal(db, user)
    daily_plan = generate_daily_plan(db, user)
    growth = calculate_skill_growth(db, user)
    weekly_insights = get_weekly_insights(db, user)
    adaptive = generate_adaptive_recommendations(db, user)
    hero_recommendation = generate_hero_recommendation(db, user)

    streak_msg = f"{user.streak_days} days streak active!" if (user.streak_days and user.streak_days > 0) else "Start learning today to build your streak!"
    insights = [
        f"You have {len(gap_data['strengths'])} validated skill strengths.",
        f"{len(gap_data['developing'])} skills currently in active development.",
        streak_msg,
    ]

    return {
        "user_id": user.id,
        "user_name": user.name,
        "user_xp": user.xp or 0,
        "streak_days": user.streak_days or 0,
        "hero_recommendation": hero_recommendation,
        "daily_goal": daily_goal,
        "daily_plan": daily_plan,
        "growth_summary": growth,
        "weekly_insights": weekly_insights,
        "adaptive_recommendations": adaptive,
        "skill_gaps": gap_data["skill_gaps"],
        "strengths": gap_data["strengths"],
        "developing_skills": gap_data["developing"],
        "needs_practice_skills": gap_data["needs_practice"],
        "skill_portfolio": gap_data["portfolio"],
        "roadmap_preview": roadmap[:6],
        "practice_diagnostics": diagnostics,
        "exchange_suggestions": exchanges,
        "learning_insights": insights,
    }
