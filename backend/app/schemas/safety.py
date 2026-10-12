from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserReportCreate(BaseModel):
    reported_user_id: int
    reason: str
    description: Optional[str] = None

class UserReportResponse(BaseModel):
    id: int
    reporter_id: int
    reported_user_id: int
    reporter_name: Optional[str] = None
    reported_user_name: Optional[str] = None
    reason: str
    description: Optional[str] = None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class ReportStatusUpdate(BaseModel):
    status: str  # pending, reviewed, resolved, dismissed

class UserBlockResponse(BaseModel):
    id: int
    blocker_id: int
    blocked_user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
