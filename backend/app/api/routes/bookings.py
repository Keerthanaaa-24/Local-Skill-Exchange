from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from ..deps import SessionDep, CurrentUser
from ...db.models import Booking, Transaction, User, Notification, Skill
from ...schemas.booking import BookingCreate, BookingResponse
from ...services import gamification_service, notification_service

router = APIRouter()

@router.post("/", response_model=BookingResponse)
@router.post("", response_model=BookingResponse)
def create_booking(booking_in: BookingCreate, db: SessionDep, current_user: CurrentUser):
    try:
        if current_user.email == "guest_user@localskillexchange.internal":
            raise HTTPException(status_code=403, detail="Guests cannot book sessions. Please register or log in.")
        # Check if mentor exists
        mentor = db.query(User).filter(User.id == booking_in.mentor_id).first()
        if not mentor:
            raise HTTPException(status_code=404, detail="Mentor not found")
        
        if mentor.id == current_user.id:
            raise HTTPException(status_code=400, detail="Cannot book yourself")

        # Check credits
        if current_user.credits < booking_in.credits_cost:
            raise HTTPException(status_code=400, detail="Not enough credits")
        
        # Create booking
        booking = Booking(
            mentee_id=current_user.id,
            mentor_id=booking_in.mentor_id,
            skill_id=booking_in.skill_id,
            date=booking_in.date,
            location=booking_in.location,
            credits_cost=booking_in.credits_cost,
            status="upcoming"
        )
        db.add(booking)
        
        # Deduct credits from mentee
        current_user.credits -= booking_in.credits_cost
        
        # Add credits to mentor (or keep in escrow until completed, but for now we add immediately)
        mentor.credits += booking_in.credits_cost
        
        # Record transactions
        tx_mentee = Transaction(
            user_id=current_user.id,
            amount=-booking_in.credits_cost,
            description=f"Paid for session with {mentor.name}"
        )
        tx_mentor = Transaction(
            user_id=mentor.id,
            amount=booking_in.credits_cost,
            description=f"Received payment for session with {current_user.name}"
        )
        db.add(tx_mentee)
        db.add(tx_mentor)
        
        skill = db.query(Skill).filter(Skill.id == booking_in.skill_id).first()
        skill_name = skill.name if skill else "Skill Exchange"
        # Notify mentor
        notification_service.create_notification(
            db=db,
            user_id=mentor.id,
            title=f"New {skill_name} Session Request",
            message=f"{current_user.name} requested a skill exchange session with you.",
            notification_type="BOOKING_REQUEST",
            target_id=booking.id,
        )
        
        db.commit()
        db.refresh(booking)
        return booking
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[BookingResponse])
@router.get("", response_model=List[BookingResponse])
def get_user_bookings(db: SessionDep, current_user: CurrentUser):
    bookings = db.query(Booking).filter(
        (Booking.mentee_id == current_user.id) | (Booking.mentor_id == current_user.id)
    ).all()
    if not getattr(current_user, "is_test_user", False):
        bookings = [
            b for b in bookings
            if b.mentee and not getattr(b.mentee, "is_test_user", False)
            and b.mentor and not getattr(b.mentor, "is_test_user", False)
        ]
    return bookings

@router.get("/upcoming/", response_model=List[BookingResponse])
@router.get("/upcoming", response_model=List[BookingResponse])
def get_upcoming_bookings(db: SessionDep, current_user: CurrentUser):
    bookings = db.query(Booking).filter(
        ((Booking.mentee_id == current_user.id) | (Booking.mentor_id == current_user.id)),
        Booking.status.in_(["upcoming", "pending", "accepted"])
    ).all()
    if not getattr(current_user, "is_test_user", False):
        bookings = [
            b for b in bookings
            if b.mentee and not getattr(b.mentee, "is_test_user", False)
            and b.mentor and not getattr(b.mentor, "is_test_user", False)
        ]
    return bookings

@router.get("/completed/", response_model=List[BookingResponse])
@router.get("/completed", response_model=List[BookingResponse])
def get_completed_bookings(db: SessionDep, current_user: CurrentUser):
    bookings = db.query(Booking).filter(
        ((Booking.mentee_id == current_user.id) | (Booking.mentor_id == current_user.id)),
        Booking.status == "completed"
    ).all()
    if not getattr(current_user, "is_test_user", False):
        bookings = [
            b for b in bookings
            if b.mentee and not getattr(b.mentee, "is_test_user", False)
            and b.mentor and not getattr(b.mentor, "is_test_user", False)
        ]
    return bookings

@router.get("/{booking_id}", response_model=BookingResponse)
def get_booking_by_id(booking_id: int, db: SessionDep, current_user: CurrentUser):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.mentee_id != current_user.id and booking.mentor_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this booking")
    if not getattr(current_user, "is_test_user", False):
        if (booking.mentee and getattr(booking.mentee, "is_test_user", False)) or (booking.mentor and getattr(booking.mentor, "is_test_user", False)):
            raise HTTPException(status_code=404, detail="Booking not found")
    return booking


@router.post("/{booking_id}/cancel")
def cancel_booking(booking_id: int, db: SessionDep, current_user: CurrentUser):
    try:
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found")
            
        if booking.mentee_id != current_user.id and booking.mentor_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized")
            
        if booking.status != "upcoming":
            raise HTTPException(status_code=400, detail="Only upcoming bookings can be canceled")
            
        booking.status = "canceled"
        
        # Refund mentee and deduct from mentor
        mentee = db.query(User).filter(User.id == booking.mentee_id).first()
        mentor = db.query(User).filter(User.id == booking.mentor_id).first()
        
        if mentee and mentor:
            mentee.credits += booking.credits_cost
            mentor.credits -= booking.credits_cost
            
            tx_refund = Transaction(
                user_id=mentee.id,
                amount=booking.credits_cost,
                description="Refund for canceled session"
            )
            tx_deduct = Transaction(
                user_id=mentor.id,
                amount=-booking.credits_cost,
                description="Deduction for canceled session"
            )
            db.add(tx_refund)
            db.add(tx_deduct)
            
        db.commit()
        return {"message": "Booking canceled successfully"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{booking_id}/accept")
def accept_booking(booking_id: int, db: SessionDep, current_user: CurrentUser):
    try:
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found")
        if booking.mentor_id != current_user.id:
            raise HTTPException(status_code=403, detail="Only the mentor can accept this session")
        if booking.status not in ["upcoming", "pending"]:
            raise HTTPException(status_code=400, detail=f"Cannot accept booking in status {booking.status}")

        booking.status = "accepted"
        skill = db.query(Skill).filter(Skill.id == booking.skill_id).first()
        skill_name = skill.name if skill else "Skill Exchange"
        notification_service.create_notification(
            db=db,
            user_id=booking.mentee_id,
            title=f"{skill_name} Session Accepted",
            message=f"Your {skill_name} session with {current_user.name} was accepted.",
            notification_type="BOOKING_ACCEPTED",
            target_id=booking.id,
        )
        db.commit()
        return {"message": "Booking accepted successfully"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{booking_id}/reject")
def reject_booking(booking_id: int, db: SessionDep, current_user: CurrentUser):
    try:
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found")
        if booking.mentor_id != current_user.id:
            raise HTTPException(status_code=403, detail="Only the mentor can reject this session")
        if booking.status not in ["upcoming", "pending"]:
            raise HTTPException(status_code=400, detail=f"Cannot reject booking in status {booking.status}")

        booking.status = "rejected"
        # Refund credits
        mentee = db.query(User).filter(User.id == booking.mentee_id).first()
        mentor = db.query(User).filter(User.id == booking.mentor_id).first()
        if mentee and mentor:
            mentee.credits += booking.credits_cost
            mentor.credits -= booking.credits_cost
            tx_refund = Transaction(
                user_id=mentee.id,
                amount=booking.credits_cost,
                description="Refund for rejected session"
            )
            tx_deduct = Transaction(
                user_id=mentor.id,
                amount=-booking.credits_cost,
                description="Deduction for rejected session"
            )
            db.add(tx_refund)
            db.add(tx_deduct)

        skill = db.query(Skill).filter(Skill.id == booking.skill_id).first()
        skill_name = skill.name if skill else "Skill Exchange"
        notification_service.create_notification(
            db=db,
            user_id=booking.mentee_id,
            title=f"{skill_name} Session Declined",
            message=f"Your session booking was declined and {booking.credits_cost} credits were refunded.",
            notification_type="BOOKING_REJECTED",
            target_id=booking.id,
        )

        db.commit()
        return {"message": "Booking rejected and credits refunded"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{booking_id}/complete")
def complete_booking(booking_id: int, db: SessionDep, current_user: CurrentUser):
    try:
        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found")
        if booking.mentee_id != current_user.id and booking.mentor_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to complete this session")
        if booking.status == "completed":
            return {"message": "Session already completed"}
        if booking.status in ["canceled", "cancelled", "rejected"]:
            raise HTTPException(status_code=400, detail="Cannot complete a canceled session")

        booking.status = "completed"
        skill = db.query(Skill).filter(Skill.id == booking.skill_id).first()
        skill_name = skill.name if skill else "Skill Exchange"

        # Award XP to both participants (idempotently with unique action key)
        mentee = db.query(User).filter(User.id == booking.mentee_id).first()
        mentor = db.query(User).filter(User.id == booking.mentor_id).first()
        if mentee:
            gamification_service.award_xp_idempotent(
                db, mentee.id, 50, f"exchange_mentee_{booking.id}", "Completed exchange session (Learner)"
            )
            gamification_service.check_and_award_achievements(db, mentee.id)
            notification_service.create_notification(
                db=db,
                user_id=mentee.id,
                title="Credits Used",
                message=f"{booking.credits_cost} credits were used for your {skill_name} learning session.",
                notification_type="CREDIT_SPENT",
                target_id=booking.id,
            )
        if mentor:
            gamification_service.award_xp_idempotent(
                db, mentor.id, 50, f"exchange_mentor_{booking.id}", "Completed exchange session (Mentor)"
            )
            gamification_service.check_and_award_achievements(db, mentor.id)
            notification_service.create_notification(
                db=db,
                user_id=mentor.id,
                title="Credits Earned!",
                message=f"You earned {booking.credits_cost} credits from teaching {skill_name}.",
                notification_type="CREDIT_EARNED",
                target_id=booking.id,
            )

        db.commit()
        return {"message": "Session marked as completed successfully"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
