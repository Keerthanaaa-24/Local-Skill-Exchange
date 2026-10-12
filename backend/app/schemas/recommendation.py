from pydantic import BaseModel
from typing import Optional

class RecommendationItem(BaseModel):
    mentor_id: int
    mentor_name: str
    mentor_profile_image: Optional[str] = None
    mentor_rating: Optional[float] = None
    mentor_review_count: Optional[int] = None
    mentor_latitude: Optional[float] = None
    mentor_longitude: Optional[float] = None
    skill_id: int
    skill_title: str
    skill_description: Optional[str] = None
    skill_category: Optional[str] = None
    skill_image_url: Optional[str] = None
    match_score: float
    explanation: str
    distance_km: Optional[float] = None
    rating: Optional[float] = None
    reason: Optional[str] = None
    can_learn: bool = True
    can_teach: bool = False
    nearby_mentors_count: int = 1

    class Config:
        from_attributes = True
