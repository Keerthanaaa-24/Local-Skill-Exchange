from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional

from ..deps import SessionDep, CurrentUser
from ...schemas.gamification import (
    GamificationDashboardOut,
    AchievementOut,
    LeaderboardEntryOut,
    GrowthMilestone,
)
from ...services import gamification_service

router = APIRouter()

@router.get("/dashboard", response_model=GamificationDashboardOut)
def get_dashboard(db: SessionDep, user: CurrentUser):
    return gamification_service.get_gamification_dashboard(db, user)

@router.get("/achievements", response_model=List[AchievementOut])
def get_achievements(db: SessionDep, user: CurrentUser):
    gamification_service.seed_achievements_if_needed(db)
    gamification_service.check_and_award_achievements(db, user.id)
    dash = gamification_service.get_gamification_dashboard(db, user)
    return dash.recent_achievements

@router.get("/leaderboard", response_model=List[LeaderboardEntryOut])
def get_leaderboard(db: SessionDep, user: CurrentUser, limit: int = 20):
    return gamification_service.get_community_leaderboard(db, limit=limit)

@router.get("/timeline/{user_id}", response_model=List[GrowthMilestone])
def get_timeline(user_id: int, db: SessionDep, user: CurrentUser, limit: int = 25):
    return gamification_service.get_growth_timeline(db, user_id=user_id, limit=limit)
