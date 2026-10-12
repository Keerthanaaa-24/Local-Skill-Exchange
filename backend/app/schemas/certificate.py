from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class CertificateOut(BaseModel):
    id: int
    certificate_number: str
    verification_code: str
    user_id: int
    learning_path_id: int
    skill_id: int
    title: str
    description: Optional[str] = None
    issued_at: datetime
    completed_at: datetime
    status: str
    recipient_name: Optional[str] = None
    skill_name: Optional[str] = None
    learning_path_title: Optional[str] = None

    class Config:
        from_attributes = True

class CertificateVerifyOut(BaseModel):
    valid: bool
    certificate_number: str
    title: str
    skill: str
    recipient_name: str
    issued_at: datetime
    status: str

    class Config:
        from_attributes = True
