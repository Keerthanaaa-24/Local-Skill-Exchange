from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Dict, Any, Optional
from datetime import datetime, timezone
from pydantic import BaseModel

from ..deps import SessionDep, CurrentUser
from ...db.models import User, Transaction, Booking

router = APIRouter()

class WalletResponse(BaseModel):
    wallet_id: int
    user_id: int
    balance: int
    total_credits_earned: int
    total_credits_spent: int
    pending_credits: int
    teaching_sessions_count: int = 0
    learning_sessions_count: int = 0
    created_at: str
    updated_at: str

class TransactionResponse(BaseModel):
    transaction_id: int
    wallet_id: int
    booking_id: Optional[int] = None
    amount: int
    transaction_type: str
    description: str
    status: str
    created_at: str

@router.get("", response_model=WalletResponse)
@router.get("/", response_model=WalletResponse)
def get_user_wallet(db: SessionDep, current_user: CurrentUser):
    """
    Returns user wallet summary derived from real User credits, sessions and Transaction history.
    """
    transactions = db.query(Transaction).filter(Transaction.user_id == current_user.id).all()
    
    total_earned = sum(t.amount for t in transactions if t.amount > 0)
    total_spent = abs(sum(t.amount for t in transactions if t.amount < 0))
    
    # Calculate pending credits from upcoming bookings where user is mentor
    pending_bookings = db.query(Booking).filter(
        Booking.mentor_id == current_user.id,
        Booking.status == "upcoming"
    ).all()
    pending_credits = sum(b.credits_cost for b in pending_bookings)

    # Calculate real teaching and learning completed sessions count
    teaching_count = db.query(Booking).filter(
        Booking.mentor_id == current_user.id,
        Booking.status == "completed"
    ).count()

    learning_count = db.query(Booking).filter(
        Booking.mentee_id == current_user.id,
        Booking.status == "completed"
    ).count()
    
    now_iso = datetime.now(timezone.utc).isoformat()
    created_iso = current_user.created_at.isoformat() if current_user.created_at else now_iso

    return WalletResponse(
        wallet_id=current_user.id,
        user_id=current_user.id,
        balance=current_user.credits or 0,
        total_credits_earned=total_earned,
        total_credits_spent=total_spent,
        pending_credits=pending_credits,
        teaching_sessions_count=teaching_count,
        learning_sessions_count=learning_count,
        created_at=created_iso,
        updated_at=now_iso,
    )

@router.get("/transactions", response_model=List[TransactionResponse])
def get_user_transactions(db: SessionDep, current_user: CurrentUser):
    """
    Returns list of user transactions ordered by date descending.
    """
    txs = (
        db.query(Transaction)
        .filter(Transaction.user_id == current_user.id)
        .order_by(Transaction.created_at.desc())
        .all()
    )

    results = []
    for t in txs:
        t_type = "credit" if t.amount > 0 else "debit"
        results.append(TransactionResponse(
            transaction_id=t.id,
            wallet_id=current_user.id,
            booking_id=None,
            amount=t.amount,
            transaction_type=t_type,
            description=t.description or ("Credit added" if t.amount > 0 else "Credit spent"),
            status="completed",
            created_at=t.created_at.isoformat() if t.created_at else datetime.now(timezone.utc).isoformat(),
        ))
    return results

@router.get("/transactions/{transaction_id}", response_model=TransactionResponse)
def get_transaction_detail(transaction_id: int, db: SessionDep, current_user: CurrentUser):
    """
    Returns specific transaction details ensuring user ownership.
    """
    t = db.query(Transaction).filter(
        Transaction.id == transaction_id,
        Transaction.user_id == current_user.id
    ).first()

    if not t:
        raise HTTPException(status_code=404, detail="Transaction not found")

    t_type = "credit" if t.amount > 0 else "debit"
    return TransactionResponse(
        transaction_id=t.id,
        wallet_id=current_user.id,
        booking_id=None,
        amount=t.amount,
        transaction_type=t_type,
        description=t.description or ("Credit added" if t.amount > 0 else "Credit spent"),
        status="completed",
        created_at=t.created_at.isoformat() if t.created_at else datetime.now(timezone.utc).isoformat(),
    )
