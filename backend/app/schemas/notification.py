from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class NotificationBase(BaseModel):
    title: str
    message: str

class NotificationCreate(NotificationBase):
    user_id: int

class NotificationResponse(NotificationBase):
    id: int
    user_id: Optional[int] = None
    type: Optional[str] = "general"
    target_id: Optional[int] = None
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True
