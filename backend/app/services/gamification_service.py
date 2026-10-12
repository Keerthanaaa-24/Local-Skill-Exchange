from datetime import datetime, timezone, timedelta, date
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Dict, Optional, Tuple, Set

from ..db.models import (
    User,
    LearningPath,
    Lesson,
    UserLearningProgress,
    PracticeAttempt,
    Certificate,
    Booking,
    Achievement,
    UserAchievement,
    UserXpLog,
    Notification,
    Skill,
)
from ..schemas.gamification import (
    AchievementOut,
    UserLevelInfo,
    LearningStreakInfo,
    LearningStats,
    GrowthMilestone,
    LeaderboardEntryOut,
    GamificationDashboardOut,
)

DEFAULT_ACHIEVEMENTS = [
    {
        "code": "first_step",
        "title": "First Step",
        "description": "Enrolled in your first skill learning path.",
        "requirement": "Start 1 learning path",
        "icon": "explore",
        "category": "learning",
    },
    {
        "code": "lesson_starter",
        "title": "Lesson Explorer",
        "description": "Completed at least 3 skill lessons.",
        "requirement": "Complete 3 lessons",
        "icon": "menu_book",
        "category": "learning",
    },
    {
        "code": "practice_ready",
        "title": "Practice Ready",
        "description": "Successfully passed your first practice quiz.",
        "requirement": "Pass 1 practice assessment (70%+ score)",
        "icon": "quiz",
        "category": "practice",
    },
    {
        "code": "certified_learner",
        "title": "Certified Learner",
        "description": "Earned your first official verified skill certificate.",
        "requirement": "Earn 1 verified certificate",
        "icon": "workspace_premium",
        "category": "certification",
    },
    {
        "code": "skill_explorer",
        "title": "Skill Explorer",
        "description": "Expanded your horizons across multiple distinct skills.",
        "requirement": "Engage with 2 or more skills",
        "icon": "hub",
        "category": "learning",
    },
    {
        "code": "community_teacher",
        "title": "Community Mentor",
        "description": "Completed a skill exchange session mentoring others.",
        "requirement": "Complete 1 session as mentor",
        "icon": "volunteer_activism",
        "category": "exchange",
    },
    {
        "code": "learning_consistency",
        "title": "Consistent Learner",
        "description": "Maintained an active learning streak across consecutive days.",
        "requirement": "Maintain 2+ days streak",
        "icon": "local_fire_department",
        "category": "streak",
    },
]

def seed_achievements_if_needed(db: Session):
    for item in DEFAULT_ACHIEVEMENTS:
        existing = db.query(Achievement).filter(Achievement.code == item["code"]).first()
        if not existing:
            ach = Achievement(
                code=item["code"],
                title=item["title"],
                description=item["description"],
                requirement=item["requirement"],
                icon=item["icon"],
                category=item["category"],
            )
            db.add(ach)
    db.commit()

def award_xp_idempotent(db: Session, user_id: int, amount: int, action_key: str, description: str = "") -> int:
    """
    Awards XP deterministically and idempotently.
    If action_key was already awarded for this user, returns 0.
    """
    existing = db.query(UserXpLog).filter(
        UserXpLog.user_id == user_id,
        UserXpLog.action_key == action_key,
    ).first()

    if existing:
        return 0

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return 0

    log = UserXpLog(
        user_id=user_id,
        action_key=action_key,
        xp_amount=amount,
        description=description,
        created_at=datetime.now(timezone.utc),
    )
    db.add(log)
    user.xp = (user.xp or 0) + amount
    db.commit()
    db.refresh(user)
    return amount

def calculate_user_level(xp: int) -> UserLevelInfo:
    """
    Calculates deterministic transparent level based on XP.
    Level 1: 0 - 99 XP
    Level 2: 100 - 249 XP
    Level 3: 250 - 499 XP
    Level 4: 500 - 999 XP
    Level 5: 1000+ XP
    """
    current_xp = max(0, xp)
    if current_xp < 100:
        level = 1
        min_xp = 0
        next_xp = 100
    elif current_xp < 250:
        level = 2
        min_xp = 100
        next_xp = 250
    elif current_xp < 500:
        level = 3
        min_xp = 250
        next_xp = 500
    elif current_xp < 1000:
        level = 4
        min_xp = 500
        next_xp = 1000
    else:
        # Level 5+
        level = 5 + (current_xp - 1000) // 1000
        min_xp = 1000 + (level - 5) * 1000
        next_xp = min_xp + 1000

    span = max(1, next_xp - min_xp)
    progress_pct = round(min(100.0, max(0.0, (current_xp - min_xp) / span * 100.0)), 1)

    return UserLevelInfo(
        level=level,
        current_xp=current_xp,
        next_level_xp=next_xp,
        current_level_min_xp=min_xp,
        level_progress_percent=progress_pct,
    )

def calculate_learning_streak(db: Session, user_id: int) -> LearningStreakInfo:
    """
    Calculates streak strictly from real historical database records.
    Collects distinct dates from:
    - PracticeAttempt.completed_at
    - Certificate.issued_at
    - UserLearningProgress.started_at, completed_at
    - Booking.date (where status == 'completed')
    """
    activity_dates: Set[date] = set()

    # 1. Practice attempts
    attempts = db.query(PracticeAttempt.completed_at).filter(PracticeAttempt.user_id == user_id).all()
    for (ca,) in attempts:
        if ca:
            activity_dates.add(ca.date())

    # 2. Certificates
    certs = db.query(Certificate.issued_at).filter(Certificate.user_id == user_id).all()
    for (ia,) in certs:
        if ia:
            activity_dates.add(ia.date())

    # 3. Learning progress
    progress_records = db.query(UserLearningProgress).filter(UserLearningProgress.user_id == user_id).all()
    for p in progress_records:
        if p.started_at:
            activity_dates.add(p.started_at.date())
        if p.completed_at:
            activity_dates.add(p.completed_at.date())

    # 4. Completed bookings
    bookings = db.query(Booking.date).filter(
        (Booking.mentor_id == user_id) | (Booking.mentee_id == user_id),
        Booking.status == "completed",
    ).all()
    for (bd,) in bookings:
        if bd:
            activity_dates.add(bd.date())

    if not activity_dates:
        return LearningStreakInfo(current_streak=0, longest_streak=0, last_active_date=None)

    sorted_dates = sorted(list(activity_dates))
    today = datetime.now(timezone.utc).date()
    yesterday = today - timedelta(days=1)

    # Activity dates up to today (ignore future scheduled bookings)
    past_or_today_dates = [d for d in sorted_dates if d <= today]
    if not past_or_today_dates:
        return LearningStreakInfo(current_streak=0, longest_streak=0, last_active_date=sorted_dates[-1].isoformat())

    last_active_date_val = past_or_today_dates[-1]

    # Calculate longest streak within past/today
    longest = 1
    current_run = 1
    for i in range(1, len(past_or_today_dates)):
        if past_or_today_dates[i] == past_or_today_dates[i - 1] + timedelta(days=1):
            current_run += 1
            if current_run > longest:
                longest = current_run
        else:
            current_run = 1

    current_streak = 0
    if last_active_date_val in (today, yesterday):
        # Count consecutive days backwards
        current_streak = 1
        target = last_active_date_val - timedelta(days=1)
        for d in reversed(past_or_today_dates[:-1]):
            if d == target:
                current_streak += 1
                target = target - timedelta(days=1)
            else:
                break

    # Update User model streak
    user = db.query(User).filter(User.id == user_id).first()
    if user and (user.streak_days or 0) != current_streak:
        user.streak_days = current_streak
        db.commit()

    return LearningStreakInfo(
        current_streak=current_streak,
        longest_streak=max(longest, current_streak),
        last_active_date=last_active_date_val.isoformat(),
    )

def check_and_award_achievements(db: Session, user_id: int) -> List[Achievement]:
    """
    Evaluates real user data against all system achievements and awards newly unlocked ones.
    Prevents duplicate awards.
    """
    seed_achievements_if_needed(db)

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return []

    # Get already earned achievement IDs
    earned_ids = {
        ua.achievement_id for ua in db.query(UserAchievement.achievement_id).filter(
            UserAchievement.user_id == user_id
        ).all()
    }

    # Fetch real stats
    all_achievements = db.query(Achievement).all()
    newly_earned: List[Achievement] = []

    # Real data metrics
    progress_list = db.query(UserLearningProgress).filter(UserLearningProgress.user_id == user_id).all()
    paths_started = len(progress_list)
    total_completed_lessons = 0
    distinct_skills: Set[int] = set()

    for p in progress_list:
        completed_ids = [x for x in (p.completed_lessons or "").split(",") if x.strip().isdigit()]
        total_completed_lessons += len(completed_ids)
        if p.learning_path and p.learning_path.skill_id:
            distinct_skills.add(p.learning_path.skill_id)

    passed_practices = db.query(PracticeAttempt).filter(
        PracticeAttempt.user_id == user_id,
        PracticeAttempt.score >= 70,
    ).count()

    certs_count = db.query(Certificate).filter(
        Certificate.user_id == user_id,
        Certificate.status == "valid",
    ).count()

    mentor_bookings = db.query(Booking).filter(
        Booking.mentor_id == user_id,
        Booking.status == "completed",
    ).count()

    streak_info = calculate_learning_streak(db, user_id)

    for ach in all_achievements:
        if ach.id in earned_ids:
            continue

        qualified = False
        if ach.code == "first_step" and paths_started >= 1:
            qualified = True
        elif ach.code == "lesson_starter" and total_completed_lessons >= 3:
            qualified = True
        elif ach.code == "practice_ready" and passed_practices >= 1:
            qualified = True
        elif ach.code == "certified_learner" and certs_count >= 1:
            qualified = True
        elif ach.code == "skill_explorer" and (len(distinct_skills) >= 2 or paths_started >= 2):
            qualified = True
        elif ach.code == "community_teacher" and mentor_bookings >= 1:
            qualified = True
        elif ach.code == "learning_consistency" and streak_info.longest_streak >= 2:
            qualified = True

        if qualified:
            ua = UserAchievement(
                user_id=user_id,
                achievement_id=ach.id,
                earned_at=datetime.now(timezone.utc),
            )
            db.add(ua)
            # In-app notification
            from . import notification_service
            notification_service.create_notification(
                db=db,
                user_id=user_id,
                title=f"Achievement Unlocked: {ach.title}",
                message=f"You earned the '{ach.title}' badge: {ach.description}",
                notification_type="ACHIEVEMENT",
                target_id=ach.id,
            )
            newly_earned.append(ach)

    if newly_earned:
        db.commit()

    return newly_earned

def get_growth_timeline(db: Session, user_id: int, limit: int = 25) -> List[GrowthMilestone]:
    """
    Constructs an authentic visual Skill Growth Timeline using actual DB events and timestamps.
    """
    milestones: List[GrowthMilestone] = []

    # 1. Path enrollments & completions
    progress_records = db.query(UserLearningProgress).filter(UserLearningProgress.user_id == user_id).all()
    for p in progress_records:
        path_title = p.learning_path.title if p.learning_path else "Skill Path"
        if p.started_at:
            milestones.append(GrowthMilestone(
                milestone_type="start_path",
                title=f"Started {path_title}",
                description=f"Enrolled in the curriculum for {path_title}.",
                timestamp=p.started_at,
                badge="explore",
            ))
        if p.completed_at:
            milestones.append(GrowthMilestone(
                milestone_type="path_completed",
                title=f"Mastered {path_title}",
                description=f"Completed 100% of curriculum lessons for {path_title}.",
                timestamp=p.completed_at,
                badge="check_circle",
            ))

    # 2. Practice passes
    passed_attempts = db.query(PracticeAttempt).filter(
        PracticeAttempt.user_id == user_id,
        PracticeAttempt.score >= 70,
    ).order_by(PracticeAttempt.completed_at.desc()).limit(10).all()

    for a in passed_attempts:
        lesson_title = a.lesson.title if a.lesson else f"Lesson #{a.lesson_id}"
        milestones.append(GrowthMilestone(
            milestone_type="practice_passed",
            title=f"Passed Practice: {lesson_title}",
            description=f"Scored {a.score}% ({a.correct_answers}/{a.total_questions} correct).",
            timestamp=a.completed_at,
            badge="quiz",
        ))

    # 3. Certificates issued
    certs = db.query(Certificate).filter(Certificate.user_id == user_id).all()
    for c in certs:
        milestones.append(GrowthMilestone(
            milestone_type="certificate_earned",
            title=f"Certificate Earned: {c.title}",
            description=f"Official certificate ID: {c.certificate_number}.",
            timestamp=c.issued_at,
            badge="workspace_premium",
        ))

    # 4. Completed exchanges
    completed_bookings = db.query(Booking).filter(
        (Booking.mentor_id == user_id) | (Booking.mentee_id == user_id),
        Booking.status == "completed",
    ).order_by(Booking.date.desc()).limit(10).all()

    for b in completed_bookings:
        role = "Mentor" if b.mentor_id == user_id else "Learner"
        skill_name = b.skill.name if b.skill else "Skill Exchange"
        partner = b.mentee if b.mentor_id == user_id else b.mentor
        partner_name = partner.name if partner else "Community Partner"
        milestones.append(GrowthMilestone(
            milestone_type="exchange_completed",
            title=f"Completed Exchange ({role})",
            description=f"Live exchange session in {skill_name} with {partner_name}.",
            timestamp=b.date or datetime.now(timezone.utc),
            badge="swap_horiz",
        ))

    # Sort all milestones chronologically descending
    milestones.sort(key=lambda m: m.timestamp, reverse=True)
    return milestones[:limit]

def get_gamification_dashboard(db: Session, user: User) -> GamificationDashboardOut:
    """
    Aggregates learning stats, level, streak, achievements, and timeline.
    """
    seed_achievements_if_needed(db)
    check_and_award_achievements(db, user.id)

    # 1. Level & XP
    level_info = calculate_user_level(user.xp or 0)

    # 2. Streak
    streak_info = calculate_learning_streak(db, user.id)

    # 3. Learning Stats
    total_paths = db.query(LearningPath).count()
    user_progs = db.query(UserLearningProgress).filter(UserLearningProgress.user_id == user.id).all()
    paths_started = len(user_progs)
    paths_completed = sum(1 for p in user_progs if p.completed_at is not None)

    lessons_completed = 0
    for p in user_progs:
        completed_ids = [x for x in (p.completed_lessons or "").split(",") if x.strip().isdigit()]
        lessons_completed += len(completed_ids)

    user_attempts = db.query(PracticeAttempt).filter(PracticeAttempt.user_id == user.id).all()
    practice_attempts = len(user_attempts)
    passed_attempts = sum(1 for a in user_attempts if a.score >= 70)
    pass_rate = round((passed_attempts / practice_attempts * 100.0), 1) if practice_attempts > 0 else 0.0

    certs_count = db.query(Certificate).filter(
        Certificate.user_id == user.id,
        Certificate.status == "valid",
    ).count()

    completed_exchanges = db.query(Booking).filter(
        (Booking.mentor_id == user.id) | (Booking.mentee_id == user.id),
        Booking.status == "completed",
    ).count()

    learning_stats = LearningStats(
        total_paths_available=total_paths,
        paths_started=paths_started,
        paths_completed=paths_completed,
        lessons_completed=lessons_completed,
        practice_attempts=practice_attempts,
        practice_pass_rate=pass_rate,
        certificates_earned=certs_count,
        completed_exchanges=completed_exchanges,
    )

    # 4. Achievements
    all_achievements = db.query(Achievement).all()
    user_achs = {
        ua.achievement_id: ua.earned_at for ua in db.query(UserAchievement).filter(
            UserAchievement.user_id == user.id
        ).all()
    }

    achievements_out: List[AchievementOut] = []
    next_achievement: Optional[AchievementOut] = None

    for a in all_achievements:
        is_unlocked = a.id in user_achs
        earned_at = user_achs.get(a.id)
        out = AchievementOut(
            id=a.id,
            code=a.code,
            title=a.title,
            description=a.description,
            requirement=a.requirement,
            icon=a.icon,
            category=a.category,
            is_unlocked=is_unlocked,
            earned_at=earned_at,
        )
        achievements_out.append(out)
        if not is_unlocked and next_achievement is None:
            next_achievement = out

    # Sort achievements: unlocked first (most recent first), then locked
    achievements_out.sort(key=lambda x: (not x.is_unlocked, x.earned_at or datetime.min), reverse=False)

    # 5. Timeline milestones
    milestones = get_growth_timeline(db, user.id, limit=6)

    return GamificationDashboardOut(
        level_info=level_info,
        streak_info=streak_info,
        learning_stats=learning_stats,
        unlocked_achievements_count=len(user_achs),
        total_achievements_count=len(all_achievements),
        recent_achievements=achievements_out,
        next_achievement=next_achievement,
        recent_milestones=milestones,
    )

def get_community_leaderboard(db: Session, limit: int = 20) -> List[LeaderboardEntryOut]:
    """
    Returns transparent community leaderboard ranked by XP and learning activity.
    Strictly sanitizes data - no emails, balances, or private logs exposed.
    """
    users = db.query(User).order_by(User.xp.desc()).limit(limit).all()
    leaderboard: List[LeaderboardEntryOut] = []

    for rank, u in enumerate(users, start=1):
        level_info = calculate_user_level(u.xp or 0)
        completed_paths = db.query(UserLearningProgress).filter(
            UserLearningProgress.user_id == u.id,
            UserLearningProgress.completed_at.isnot(None),
        ).count()
        certs_count = db.query(Certificate).filter(
            Certificate.user_id == u.id,
            Certificate.status == "valid",
        ).count()
        completed_exchanges = db.query(Booking).filter(
            (Booking.mentor_id == u.id) | (Booking.mentee_id == u.id),
            Booking.status == "completed",
        ).count()

        leaderboard.append(LeaderboardEntryOut(
            rank=rank,
            user_id=u.id,
            name=u.name,
            title=u.title or "Skill Enthusiast",
            avatar_url=u.avatar_url,
            xp=u.xp or 0,
            level=level_info.level,
            completed_paths=completed_paths,
            certificates_count=certs_count,
            completed_exchanges=completed_exchanges,
        ))

    return leaderboard
