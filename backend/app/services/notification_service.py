from sqlalchemy.orm import Session
from datetime import datetime, timezone
from typing import Optional
from ..db.models import Notification

def create_notification(
    db: Session,
    user_id: int,
    title: str,
    message: str,
    notification_type: str = "general",
    target_id: Optional[int] = None,
) -> Optional[Notification]:
    """
    Creates and persists a real, event-driven notification for the specified user.
    Deduplicates identical unread notifications to avoid spamming the user.
    """
    if not user_id or not title:
        return None

    # Check for identical unread notification created recently
    existing = (
        db.query(Notification)
        .filter(
            Notification.user_id == user_id,
            Notification.title == title,
            Notification.message == message,
            Notification.is_read == False,
        )
        .order_by(Notification.created_at.desc())
        .first()
    )
    if existing:
        return existing

    notif = Notification(
        user_id=user_id,
        title=title,
        message=message,
        type=notification_type,
        target_id=target_id,
        is_read=False,
        created_at=datetime.now(timezone.utc),
    )
    db.add(notif)
    try:
        db.commit()
        db.refresh(notif)
    except Exception as e:
        db.rollback()
        print(f"Error creating notification for user {user_id}: {e}")
        return None
    return notif
