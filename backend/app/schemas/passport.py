from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class PassportProfile(BaseModel):
    user_id: int
    name: str
    email: Optional[str] = None
    title: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    location: Optional[str] = None
    xp: int = 0
    streak_days: int = 0
    credits: Optional[int] = None

    class Config:
        from_attributes = True

class PassportSkill(BaseModel):
    skill_id: int
    skill_name: str
    category: Optional[str] = None
    level: str  # Beginner, Intermediate, Advanced
    learning_progress: float  # 0.0 - 100.0
    completed_learning_paths: int = 0
    certificates_count: int = 0
    practice_average: Optional[float] = None
    is_certified: bool = False

    class Config:
        from_attributes = True

class PassportCertificate(BaseModel):
    certificate_id: int
    certificate_number: str
    title: str
    skill: str
    skill_id: int
    issued_at: datetime
    verification_code: str
    status: str

    class Config:
        from_attributes = True

class PassportPracticeSummary(BaseModel):
    total_attempts: int = 0
    passed_attempts: int = 0
    average_score: Optional[float] = None
    highest_score: Optional[int] = None
    lessons_practiced: int = 0

    class Config:
        from_attributes = True

class PassportLearningSummary(BaseModel):
    active_paths: int = 0
    completed_paths: int = 0
    total_lessons_completed: int = 0
    total_lessons_available: int = 0
    overall_progress: float = 0.0

    class Config:
        from_attributes = True

class PassportExchangeSummary(BaseModel):
    skills_offered_count: int = 0
    skills_requested_count: int = 0
    completed_bookings_as_mentor: int = 0
    completed_bookings_as_mentee: int = 0
    total_completed_exchanges: int = 0
    credits_earned: Optional[int] = None
    credits_spent: Optional[int] = None
    average_rating: float = 5.0
    total_reviews: int = 0

    class Config:
        from_attributes = True

class SkillPassportResponse(BaseModel):
    profile: PassportProfile
    learning_summary: PassportLearningSummary
    practice_summary: PassportPracticeSummary
    skills: List[PassportSkill] = []
    certificates: List[PassportCertificate] = []
    exchange_summary: PassportExchangeSummary
    is_public_view: bool = False

    class Config:
        from_attributes = True
