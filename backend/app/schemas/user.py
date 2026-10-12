from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime
from .skill import SkillBase

class UserBase(BaseModel):
    email: EmailStr
    name: str

class UserCreate(UserBase):
    password: str
    is_test_user: Optional[bool] = False

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserSkill(BaseModel):
    skill: SkillBase

    class Config:
        from_attributes = True

class UserResponse(UserBase):
    id: int
    title: str
    avatar_url: str
    rating: float
    reviews: int
    xp: int
    credits: int
    streak_days: int
    is_online: bool
    is_admin: bool
    is_test_user: bool = False
    lat: Optional[float] = None
    lng: Optional[float] = None
    distance_km: Optional[float] = None
    created_at: datetime
    
    skills_offered: List[UserSkill] = []
    skills_wanted: List[UserSkill] = []

    class Config:
        from_attributes = True
