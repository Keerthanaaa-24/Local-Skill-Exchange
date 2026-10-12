from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from ..deps import SessionDep, CurrentUser, OptionalCurrentUser
from ...db.models import Review, User, Booking, Notification
from ...schemas.review import ReviewCreate, ReviewUpdate, ReviewResponse, RatingStatsResponse

router = APIRouter()

def _format_review_response(review: Review) -> ReviewResponse:
    reviewer_name = review.reviewer.name if review.reviewer else "Anonymous"
    reviewer_avatar = review.reviewer.avatar_url if review.reviewer else None
    return ReviewResponse(
        id=review.id,
        review_id=review.id,
        booking_id=review.booking_id,
        reviewer_id=review.reviewer_id,
        reviewer_name=reviewer_name,
        reviewer_image_url=reviewer_avatar,
        reviewee_id=review.reviewee_id,
        reviewed_user_id=review.reviewee_id,
        rating=review.rating,
        comment=review.comment,
        created_at=review.created_at,
        updated_at=review.created_at
    )

@router.post("/", response_model=ReviewResponse)
@router.post("", response_model=ReviewResponse)
def create_review(review_in: ReviewCreate, db: SessionDep, current_user: CurrentUser):
    target_reviewee_id = review_in.reviewed_user_id or review_in.reviewee_id
    if not target_reviewee_id:
        raise HTTPException(status_code=400, detail="Must provide reviewee_id or reviewed_user_id")

    # Ensure booking exists
    booking = db.query(Booking).filter(Booking.id == review_in.booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    if booking.status != "completed":
        raise HTTPException(status_code=400, detail="Can only review completed sessions")
        
    if booking.mentee_id != current_user.id and booking.mentor_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to review this session")

    # Check for duplicate review
    existing_review = db.query(Review).filter(
        Review.booking_id == review_in.booking_id,
        Review.reviewer_id == current_user.id
    ).first()
    if existing_review:
        raise HTTPException(status_code=400, detail="You have already submitted a review for this session")

    # Create the review
    review = Review(
        reviewer_id=current_user.id,
        reviewee_id=target_reviewee_id,
        booking_id=review_in.booking_id,
        rating=review_in.rating,
        comment=review_in.comment
    )
    db.add(review)
    
    # Update user's average rating
    reviewee = db.query(User).filter(User.id == target_reviewee_id).first()
    if reviewee:
        current_reviews = reviewee.reviews or 0
        current_rating = reviewee.rating or 5.0
        new_rating = ((current_rating * current_reviews) + review_in.rating) / (current_reviews + 1)
        reviewee.rating = round(new_rating, 2)
        reviewee.reviews = current_reviews + 1
        
    # Send notification to reviewee
    from ...services import notification_service
    notification_service.create_notification(
        db=db,
        user_id=target_reviewee_id,
        title="New Review Received!",
        message=f"{current_user.name} gave you {review_in.rating}★: \"{review_in.comment}\"",
        notification_type="REVIEW_RECEIVED",
        target_id=review.id,
    )

    db.commit()
    db.refresh(review)
    return _format_review_response(review)

@router.get("/user/{user_id}", response_model=List[ReviewResponse])
def get_user_reviews(user_id: int, db: SessionDep, current_user: OptionalCurrentUser = None):
    reviews = db.query(Review).filter(Review.reviewee_id == user_id).all()
    if not current_user or not getattr(current_user, "is_test_user", False):
        reviews = [r for r in reviews if r.reviewer and not getattr(r.reviewer, "is_test_user", False)]
    return [_format_review_response(r) for r in reviews]

@router.get("/user/{user_id}/statistics", response_model=RatingStatsResponse)
@router.get("/user/{user_id}/stats", response_model=RatingStatsResponse)
def get_user_rating_statistics(user_id: int, db: SessionDep, current_user: OptionalCurrentUser = None):
    reviews = db.query(Review).filter(Review.reviewee_id == user_id).all()
    if not current_user or not getattr(current_user, "is_test_user", False):
        reviews = [r for r in reviews if r.reviewer and not getattr(r.reviewer, "is_test_user", False)]
    total = len(reviews)
    if total == 0:
        return RatingStatsResponse(
            average_rating=5.0,
            total_reviews=0,
            five_star=0,
            four_star=0,
            three_star=0,
            two_star=0,
            one_star=0,
        )
    
    avg = sum(r.rating for r in reviews) / total
    five = sum(1 for r in reviews if round(r.rating) == 5)
    four = sum(1 for r in reviews if round(r.rating) == 4)
    three = sum(1 for r in reviews if round(r.rating) == 3)
    two = sum(1 for r in reviews if round(r.rating) == 2)
    one = sum(1 for r in reviews if round(r.rating) == 1)
    
    return RatingStatsResponse(
        average_rating=round(avg, 2),
        total_reviews=total,
        five_star=five,
        four_star=four,
        three_star=three,
        two_star=two,
        one_star=one,
    )

@router.get("/{review_id}", response_model=ReviewResponse)
def get_review_by_id(review_id: int, db: SessionDep):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    return _format_review_response(review)

@router.put("/{review_id}", response_model=ReviewResponse)
def update_review(review_id: int, review_in: ReviewUpdate, db: SessionDep, current_user: CurrentUser):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    if review.reviewer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this review")
    
    if review_in.rating is not None:
        review.rating = review_in.rating
    if review_in.comment is not None:
        review.comment = review_in.comment
        
    db.commit()
    db.refresh(review)
    return _format_review_response(review)

@router.delete("/{review_id}")
def delete_review(review_id: int, db: SessionDep, current_user: CurrentUser):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    if review.reviewer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this review")
    
    db.delete(review)
    db.commit()
    return {"status": "ok"}

