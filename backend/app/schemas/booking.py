from pydantic import BaseModel, model_validator
from typing import Optional, Any
from datetime import datetime

class BookingBase(BaseModel):
    mentor_id: int
    skill_id: int
    date: Optional[datetime] = None
    location: Optional[str] = "online"
    credits_cost: Optional[int] = 10

class BookingCreate(BaseModel):
    mentor_id: int
    skill_id: int
    date: Optional[datetime] = None
    booking_date: Optional[str] = None
    booking_time: Optional[str] = None
    location: Optional[str] = None
    meeting_type: Optional[str] = None
    credits_cost: Optional[int] = None
    credits: Optional[int] = None
    duration: Optional[int] = 60
    notes: Optional[str] = None
    skill_title: Optional[str] = None
    mentor_name: Optional[str] = None
    learner_id: Optional[int] = None
    learner_name: Optional[str] = None
    booking_status: Optional[str] = None

    @model_validator(mode='before')
    @classmethod
    def reconcile_booking_fields(cls, data: Any):
        if isinstance(data, dict):
            # Parse date from booking_date and booking_time if date is omitted
            if not data.get("date"):
                b_date = data.get("booking_date")
                b_time = data.get("booking_time") or "10:00"
                if b_date:
                    try:
                        data["date"] = datetime.fromisoformat(f"{b_date}T{b_time}:00")
                    except Exception:
                        try:
                            data["date"] = datetime.strptime(f"{b_date} {b_time}", "%Y-%m-%d %H:%M")
                        except Exception:
                            data["date"] = datetime.now()
                else:
                    data["date"] = datetime.now()
            
            # Reconcile location from meeting_type if location is omitted
            if not data.get("location"):
                data["location"] = data.get("meeting_type") or "online"

            # Reconcile credits_cost
            if data.get("credits_cost") is None:
                if data.get("credits") is not None and data.get("credits") > 0:
                    data["credits_cost"] = data.get("credits")
                else:
                    data["credits_cost"] = 10
        return data

class BookingResponse(BaseModel):
    id: int
    mentee_id: int
    mentor_id: int
    skill_id: int
    date: datetime
    location: str
    credits_cost: int
    status: str

    # Helper properties for Flutter client
    learner_id: Optional[int] = None
    learner_name: Optional[str] = None
    mentor_name: Optional[str] = None
    skill_title: Optional[str] = None
    booking_date: Optional[str] = None
    booking_time: Optional[str] = None
    booking_status: Optional[str] = None
    meeting_type: Optional[str] = None
    credits: Optional[int] = None

    class Config:
        from_attributes = True
