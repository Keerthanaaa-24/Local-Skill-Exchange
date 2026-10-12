from pydantic import BaseModel
from typing import Optional, List, Any
from datetime import datetime

class CommunityActivityItem(BaseModel):
    id: str
    type: str  # 'certificate', 'path_completed', 'exchange_completed', 'review'
    title: str
    description: str
    timestamp: datetime
    user_id: int
    user_name: str
    user_avatar: Optional[str] = None
    skill_id: Optional[int] = None
    skill_name: Optional[str] = None
    rating: Optional[float] = None

    class Config:
        from_attributes = True

class CommunityTrustIndicators(BaseModel):
    verified_certificates_count: int = 0
    completed_exchanges: int = 0
    rating: float = 5.0
    review_count: int = 0
    skills_offered_count: int = 0
    skills_learned_count: int = 0
    learning_progress_percent: float = 0.0
    is_verified_mentor: bool = False

    class Config:
        from_attributes = True

class CommunityProfileResponse(BaseModel):
    user_id: int
    name: str
    title: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    trust_indicators: CommunityTrustIndicators
    skills_offered: List[dict] = []
    skills_wanted: List[dict] = []
    recent_activity: List[CommunityActivityItem] = []
    is_blocked: bool = False

    class Config:
        from_attributes = True

class CommunityDiscoveryPeer(BaseModel):
    user_id: int
    name: str
    title: Optional[str] = None
    avatar_url: Optional[str] = None
    rating: float = 5.0
    review_count: int = 0
    distance_km: Optional[float] = None
    common_skill: Optional[str] = None
    reason: str
    trust_badges: List[str] = []

    class Config:
        from_attributes = True

class CommunityDiscoveryResponse(BaseModel):
    mentors_for_you: List[CommunityDiscoveryPeer] = []
    learning_peers: List[CommunityDiscoveryPeer] = []
    nearby_partners: List[CommunityDiscoveryPeer] = []
