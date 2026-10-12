from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class AchievementOut(BaseModel):
    id: int
    code: str
    title: str
    description: str
    requirement: str
    icon: str
    category: str
    is_unlocked: bool = False
    earned_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class UserLevelInfo(BaseModel):
    level: int
    current_xp: int
    next_level_xp: int
    current_level_min_xp: int
    level_progress_percent: float

class LearningStreakInfo(BaseModel):
    current_streak: int
    longest_streak: int
    last_active_date: Optional[str] = None

class LearningStats(BaseModel):
    total_paths_available: int
    paths_started: int
    paths_completed: int
    lessons_completed: int
    practice_attempts: int
    practice_pass_rate: float
    certificates_earned: int
    completed_exchanges: int

class GrowthMilestone(BaseModel):
    milestone_type: str
    title: str
    description: str
    timestamp: datetime
    badge: Optional[str] = None

class LeaderboardEntryOut(BaseModel):
    rank: int
    user_id: int
    name: str
    title: Optional[str] = None
    avatar_url: Optional[str] = None
    xp: int
    level: int
    completed_paths: int
    certificates_count: int
    completed_exchanges: int

class GamificationDashboardOut(BaseModel):
    level_info: UserLevelInfo
    streak_info: LearningStreakInfo
    learning_stats: LearningStats
    unlocked_achievements_count: int
    total_achievements_count: int
    recent_achievements: List[AchievementOut]
    next_achievement: Optional[AchievementOut] = None
    recent_milestones: List[GrowthMilestone]
