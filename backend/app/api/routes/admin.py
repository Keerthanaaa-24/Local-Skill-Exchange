from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional

from ..deps import SessionDep, admin_required
from ...db.models import User, Skill, Booking, Review, UserReport
from ...schemas.user import UserResponse
from ...schemas.skill import SkillBase
from ...schemas.booking import BookingResponse
from ...schemas.review import ReviewResponse
from ...schemas.safety import UserReportResponse, ReportStatusUpdate

router = APIRouter()

@router.get("/stats", tags=["admin"])
def get_admin_stats(
    db: SessionDep,
    admin_user: User = Depends(admin_required)
):
    total_users = db.query(User).count()
    online_users = db.query(User).filter(User.is_online == True).count()
    total_skills = db.query(Skill).count()
    total_bookings = db.query(Booking).count()
    total_reviews = db.query(Review).count()
    # Assuming there is a credit field on User and a transaction model for total credits
    total_credits = db.query(User).with_entities(func.coalesce(func.sum(User.credits), 0)).scalar() or 0
    return {
        "total_users": total_users,
        "online_users": online_users,
        "total_skills": total_skills,
        "total_bookings": total_bookings,
        "total_reviews": total_reviews,
        "total_credits": total_credits,
    }

@router.get("/users", response_model=List[UserResponse], tags=["admin"])
def list_users(
    db: SessionDep,
    admin_user: User = Depends(admin_required),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None),
):
    query = db.query(User)
    if search:
        search_term = f"%{search}%"
        query = query.filter((User.name.ilike(search_term)) | (User.email.ilike(search_term)))
    users = query.offset(skip).limit(limit).all()
    return users

@router.get("/skills", response_model=List[SkillBase], tags=["admin"])
def list_skills(
    db: SessionDep,
    admin_user: User = Depends(admin_required),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    skills = db.query(Skill).offset(skip).limit(limit).all()
    return skills

@router.get("/bookings", response_model=List[BookingResponse], tags=["admin"])
def list_bookings(
    db: SessionDep,
    admin_user: User = Depends(admin_required),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query(None),
):
    query = db.query(Booking)
    if status:
        query = query.filter(Booking.status == status)
    bookings = query.offset(skip).limit(limit).all()
    return bookings

@router.get("/reviews", response_model=List[ReviewResponse], tags=["admin"])
def list_reviews(
    db: SessionDep,
    admin_user: User = Depends(admin_required),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    reviews = db.query(Review).offset(skip).limit(limit).all()
    return reviews

@router.get("/reports", response_model=List[UserReportResponse], tags=["admin"])
def list_reports(
    db: SessionDep,
    admin_user: User = Depends(admin_required),
    status: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    query = db.query(UserReport)
    if status:
        query = query.filter(UserReport.status == status)
    reports = query.order_by(UserReport.created_at.desc()).offset(skip).limit(limit).all()
    # Enrich with names
    for r in reports:
        if r.reporter:
            r.reporter_name = r.reporter.name
        if r.reported_user:
            r.reported_user_name = r.reported_user.name
    return reports

@router.post("/reports/{report_id}/status", response_model=dict, tags=["admin"])
def update_report_status(
    report_id: int,
    status_in: ReportStatusUpdate,
    db: SessionDep,
    admin_user: User = Depends(admin_required),
):
    report = db.query(UserReport).filter(UserReport.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    report.status = status_in.status
    db.commit()
    return {"message": f"Report status updated to {report.status}", "status": report.status, "id": report.id}

