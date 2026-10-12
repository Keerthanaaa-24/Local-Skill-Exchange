from fastapi import APIRouter, Depends
from typing import List

from ..deps import SessionDep, CurrentUser
from ...db.models import Notification
from ...schemas.notification import NotificationResponse

router = APIRouter()

@router.get("/", response_model=List[NotificationResponse])
@router.get("", response_model=List[NotificationResponse])
def get_notifications(db: SessionDep, current_user: CurrentUser):
    notifications = (
        db.query(Notification)
        .filter(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
        .all()
    )
    if not getattr(current_user, "is_test_user", False):
        clean_notifications = []
        for n in notifications:
            title_lower = (n.title or "").lower()
            msg_lower = (n.message or "").lower()
            if "user two" in msg_lower or "test user" in msg_lower or "e2e tester" in msg_lower or "skilldirecttestsuccess" in msg_lower or "skilldirecttestsuccess" in title_lower:
                continue
            clean_notifications.append(n)
        notifications = clean_notifications
    return notifications

@router.post("/{notification_id}/read")
def mark_read(notification_id: int, db: SessionDep, current_user: CurrentUser):
    notification = (
        db.query(Notification)
        .filter(
            Notification.id == notification_id,
            Notification.user_id == current_user.id,
        )
        .first()
    )
    if notification:
        notification.is_read = True
        db.commit()
    return {"status": "ok"}

@router.post("/read-all")
def mark_all_read(db: SessionDep, current_user: CurrentUser):
    # Mark all notifications for the authenticated user as read
    db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False,
    ).update({"is_read": True})
    db.commit()
    return {"status": "ok"}

@router.delete("/{notification_id}")
def delete_notification(notification_id: int, db: SessionDep, current_user: CurrentUser):
    notification = (
        db.query(Notification)
        .filter(
            Notification.id == notification_id,
            Notification.user_id == current_user.id,
        )
        .first()
    )
    if notification:
        db.delete(notification)
        db.commit()
    return {"status": "ok"}

@router.delete("/")
@router.delete("")
def clear_all_notifications(db: SessionDep, current_user: CurrentUser):
    db.query(Notification).filter(
        Notification.user_id == current_user.id,
    ).delete(synchronize_session=False)
    db.commit()
    return {"status": "ok"}
