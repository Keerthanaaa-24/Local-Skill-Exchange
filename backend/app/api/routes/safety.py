from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List

from ..deps import SessionDep, CurrentUser
from ...db.models import User, UserReport, UserBlock
from ...schemas.safety import UserReportCreate, UserReportResponse, UserBlockResponse

router = APIRouter()

@router.post("/report", response_model=dict)
def report_user(report_in: UserReportCreate, db: SessionDep, current_user: CurrentUser):
    if report_in.reported_user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot report yourself")

    reported_user = db.query(User).filter(User.id == report_in.reported_user_id).first()
    if not reported_user:
        raise HTTPException(status_code=404, detail="Reported user not found")

    existing_pending = db.query(UserReport).filter(
        UserReport.reporter_id == current_user.id,
        UserReport.reported_user_id == report_in.reported_user_id,
        UserReport.status == "pending"
    ).first()
    if existing_pending:
        raise HTTPException(
            status_code=400,
            detail="You already have a pending report for this user."
        )

    report = UserReport(
        reporter_id=current_user.id,
        reported_user_id=report_in.reported_user_id,
        reason=report_in.reason,
        description=report_in.description,
        status="pending"
    )
    db.add(report)
    db.commit()
    db.refresh(report)

    return {
        "message": "Report submitted successfully. Our safety team will review it.",
        "report_id": report.id,
        "id": report.id
    }

@router.post("/block/{user_id}", response_model=dict)
def block_user(user_id: int, db: SessionDep, current_user: CurrentUser):
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot block yourself")

    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")

    existing = db.query(UserBlock).filter(
        UserBlock.blocker_id == current_user.id,
        UserBlock.blocked_user_id == user_id
    ).first()

    if not existing:
        block = UserBlock(blocker_id=current_user.id, blocked_user_id=user_id)
        db.add(block)
        db.commit()

    return {"message": f"User {target_user.name} has been blocked."}

@router.delete("/block/{user_id}", response_model=dict)
def unblock_user(user_id: int, db: SessionDep, current_user: CurrentUser):
    block = db.query(UserBlock).filter(
        UserBlock.blocker_id == current_user.id,
        UserBlock.blocked_user_id == user_id
    ).first()

    if block:
        db.delete(block)
        db.commit()

    return {"message": "User unblocked successfully."}

@router.get("/blocks", response_model=List[int])
def get_blocked_users(db: SessionDep, current_user: CurrentUser):
    blocks = db.query(UserBlock).filter(UserBlock.blocker_id == current_user.id).all()
    return [b.blocked_user_id for b in blocks]
