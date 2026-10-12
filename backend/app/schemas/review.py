from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ReviewBase(BaseModel):
    booking_id: int
    rating: float
    comment: str

class ReviewCreate(BaseModel):
    booking_id: int
    rating: float
    comment: str
    reviewee_id: Optional[int] = None
    reviewed_user_id: Optional[int] = None

class ReviewUpdate(BaseModel):
    rating: Optional[float] = None
    comment: Optional[str] = None

class ReviewResponse(BaseModel):
    id: int
    review_id: Optional[int] = None
    booking_id: int
    reviewer_id: int
    reviewer_name: Optional[str] = "Anonymous"
    reviewer_image_url: Optional[str] = None
    reviewee_id: int
    reviewed_user_id: Optional[int] = None
    rating: float
    comment: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class RatingStatsResponse(BaseModel):
    average_rating: float
    total_reviews: int
    five_star: int
    four_star: int
    three_star: int
    two_star: int
    one_star: int

