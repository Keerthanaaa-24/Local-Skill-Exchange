from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from typing import List, Dict, Any
from datetime import datetime, timezone
import json

from ..deps import SessionDep, CurrentUser, get_current_user_ws
from ...db.models import Message, User, UserBlock
from ...schemas.chat import MessageResponse, MessageCreate

router = APIRouter()

# Store active connections
# Map of user_id to WebSocket
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, WebSocket] = {}

    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        self.active_connections[user_id] = websocket

    def disconnect(self, user_id: int):
        if user_id in self.active_connections:
            del self.active_connections[user_id]

    async def send_personal_message(self, message: str, user_id: int):
        if user_id in self.active_connections:
            await self.active_connections[user_id].send_text(message)

manager = ConnectionManager()

@router.get("/conversations", response_model=List[Dict[str, Any]])
@router.get("/recent", response_model=List[Dict[str, Any]])
@router.get("/", response_model=List[Dict[str, Any]])
@router.get("", response_model=List[Dict[str, Any]])
def get_conversations(
    db: SessionDep,
    current_user: CurrentUser,
    include_test_users: bool = False,
):
    """
    Returns the user's active conversations derived from real Message records.
    Filters out test accounts when accessed by real users.
    """
    all_msgs = (
        db.query(Message)
        .filter((Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id))
        .order_by(Message.timestamp.desc())
        .all()
    )

    conversations_map: Dict[int, Message] = {}
    unread_counts: Dict[int, int] = {}

    for msg in all_msgs:
        partner_id = msg.receiver_id if msg.sender_id == current_user.id else msg.sender_id
        if partner_id not in conversations_map:
            conversations_map[partner_id] = msg
        if msg.receiver_id == current_user.id and not msg.is_read:
            unread_counts[partner_id] = unread_counts.get(partner_id, 0) + 1

    should_filter_test = (not getattr(current_user, "is_test_user", False)) and (
        not include_test_users or str(include_test_users).lower() in ("false", "0")
    )

    results = []
    for partner_id, latest_msg in conversations_map.items():
        partner = db.query(User).filter(User.id == partner_id).first()
        if not partner:
            continue
        if should_filter_test and partner.is_test_user:
            continue

        msg_time = latest_msg.timestamp.isoformat() if latest_msg and latest_msg.timestamp else datetime.now(timezone.utc).isoformat()
        results.append({
            "id": partner.id,
            "chat_id": partner.id,
            "partner_name": partner.name,
            "partner_avatar": partner.avatar_url or "",
            "mentor_id": partner.id,
            "mentor_name": partner.name,
            "mentor_image": partner.avatar_url or "",
            "learner_id": current_user.id,
            "learner_name": current_user.name,
            "skill_title": partner.title or "Member",
            "last_message": latest_msg.content if latest_msg else "",
            "last_message_time": msg_time,
            "unread_count": unread_counts.get(partner.id, 0),
            "is_online": bool(partner.is_online),
            "created_at": msg_time,
            "updated_at": msg_time,
        })

    return results

@router.get("/{chat_id}/messages", response_model=List[Dict[str, Any]])
@router.get("/history/{chat_id}", response_model=List[Dict[str, Any]])
def get_chat_messages(
    chat_id: int,
    db: SessionDep,
    current_user: CurrentUser,
    include_test_users: bool = False,
):
    partner = db.query(User).filter(User.id == chat_id).first()
    if not partner:
        return []

    should_filter_test = (not getattr(current_user, "is_test_user", False)) and (
        not include_test_users or str(include_test_users).lower() in ("false", "0")
    )
    if should_filter_test and partner.is_test_user:
        return []

    # Check if blocked
    blocked = db.query(UserBlock).filter(
        ((UserBlock.blocker_id == current_user.id) & (UserBlock.blocked_user_id == chat_id)) |
        ((UserBlock.blocker_id == chat_id) & (UserBlock.blocked_user_id == current_user.id))
    ).first()
    if blocked:
        return []

    messages = db.query(Message).filter(
        ((Message.sender_id == current_user.id) & (Message.receiver_id == chat_id)) |
        ((Message.sender_id == chat_id) & (Message.receiver_id == current_user.id))
    ).order_by(Message.timestamp.asc()).all()

    return [
        {
            "id": msg.id,
            "chat_id": chat_id,
            "sender_id": msg.sender_id,
            "receiver_id": msg.receiver_id,
            "content": msg.content,
            "message": msg.content,
            "message_type": "text",
            "timestamp": msg.timestamp.isoformat() if msg.timestamp else datetime.now(timezone.utc).isoformat(),
            "is_read": bool(msg.is_read),
            "attachment_url": None,
        }
        for msg in messages
    ]

@router.get("/{chat_id}", response_model=Dict[str, Any])
def get_chat_detail(
    chat_id: int,
    db: SessionDep,
    current_user: CurrentUser,
    include_test_users: bool = False,
):
    partner = db.query(User).filter(User.id == chat_id).first()
    if not partner:
        raise HTTPException(status_code=404, detail="Chat partner not found")

    should_filter_test = (not getattr(current_user, "is_test_user", False)) and (
        not include_test_users or str(include_test_users).lower() in ("false", "0")
    )
    if should_filter_test and partner.is_test_user:
        raise HTTPException(status_code=404, detail="Chat partner not found")

    latest_msg = (
        db.query(Message)
        .filter(
            ((Message.sender_id == current_user.id) & (Message.receiver_id == chat_id)) |
            ((Message.sender_id == chat_id) & (Message.receiver_id == current_user.id))
        )
        .order_by(Message.timestamp.desc())
        .first()
    )
    unread_count = db.query(Message).filter(
        Message.sender_id == chat_id,
        Message.receiver_id == current_user.id,
        Message.is_read == False
    ).count()

    last_msg_text = latest_msg.content if latest_msg else ""
    last_msg_time = latest_msg.timestamp.isoformat() if latest_msg and latest_msg.timestamp else datetime.now(timezone.utc).isoformat()

    return {
        "id": partner.id,
        "chat_id": partner.id,
        "partner_name": partner.name,
        "partner_avatar": partner.avatar_url or "",
        "mentor_id": partner.id,
        "mentor_name": partner.name,
        "mentor_image": partner.avatar_url or "",
        "learner_id": current_user.id,
        "learner_name": current_user.name,
        "skill_title": partner.title or "Member",
        "last_message": last_msg_text,
        "last_message_time": last_msg_time,
        "unread_count": unread_count,
        "is_online": bool(partner.is_online),
        "created_at": last_msg_time,
        "updated_at": last_msg_time,
    }

@router.delete("/messages/{message_id}")
@router.delete("/{message_id}")
def delete_message(message_id: int, db: SessionDep, current_user: CurrentUser):
    msg = db.query(Message).filter(Message.id == message_id).first()
    if msg and (msg.sender_id == current_user.id or msg.receiver_id == current_user.id):
        db.delete(msg)
        db.commit()
    return {"status": "ok"}

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str, db: SessionDep):
    user = await get_current_user_ws(token, db)
    if not user:
        await websocket.close(code=1008)
        return
        
    await manager.connect(websocket, user.id)
    try:
        while True:
            data = await websocket.receive_text()
            try:
                payload = json.loads(data)
            except Exception:
                continue

            if not isinstance(payload, dict):
                continue

            msg_type = payload.get("type", "message")
            if msg_type == "ping":
                await manager.send_personal_message(json.dumps({"type": "pong"}), user.id)
                continue
            if msg_type == "pong":
                continue

            raw_receiver = payload.get("receiver_id")
            receiver_id = int(raw_receiver) if raw_receiver is not None else None
            content = payload.get("content") or payload.get("message") or payload.get("text")

            if msg_type == "typing" and receiver_id:
                await manager.send_personal_message(json.dumps({
                    "type": "typing",
                    "sender_id": user.id,
                    "chat_id": user.id,
                    "is_typing": payload.get("is_typing", True)
                }), receiver_id)
                continue

            if msg_type == "read":
                msg_id = payload.get("message_id")
                if msg_id:
                    db.query(Message).filter(Message.id == int(msg_id), Message.receiver_id == user.id).update({"is_read": True})
                    db.commit()
                continue

            if receiver_id and content:
                if user.email == "guest_user@localskillexchange.internal":
                    err_payload = {"type": "error", "message": "Guests cannot send messages. Please register or log in."}
                    await manager.send_personal_message(json.dumps(err_payload), user.id)
                    continue
                receiver_user = db.query(User).filter(User.id == receiver_id).first()
                if not getattr(user, "is_test_user", False) and receiver_user and getattr(receiver_user, "is_test_user", False):
                    err_payload = {"type": "error", "message": "User not available for messaging."}
                    await manager.send_personal_message(json.dumps(err_payload), user.id)
                    continue

                # Check blocking
                is_blocked = db.query(UserBlock).filter(
                    ((UserBlock.blocker_id == user.id) & (UserBlock.blocked_user_id == receiver_id)) |
                    ((UserBlock.blocker_id == receiver_id) & (UserBlock.blocked_user_id == user.id))
                ).first()
                if is_blocked:
                    err_payload = {"type": "error", "message": "Cannot deliver message due to block settings."}
                    await manager.send_personal_message(json.dumps(err_payload), user.id)
                    continue

                # Save to db
                msg = Message(
                    sender_id=user.id,
                    receiver_id=receiver_id,
                    content=str(content)
                )
                db.add(msg)
                db.commit()
                db.refresh(msg)

                # Create event notification for recipient
                from ...services import notification_service
                notification_service.create_notification(
                    db=db,
                    user_id=receiver_id,
                    title="New Message",
                    message=f"You received a new message from {user.name}.",
                    notification_type="CHAT_MESSAGE",
                    target_id=user.id,
                )
                
                # Send to receiver if online
                response_data = {
                    "id": msg.id,
                    "chat_id": msg.sender_id,
                    "sender_id": msg.sender_id,
                    "receiver_id": msg.receiver_id,
                    "content": msg.content,
                    "message": msg.content,
                    "message_type": payload.get("message_type", "text"),
                    "timestamp": msg.timestamp.isoformat() if msg.timestamp else datetime.now(timezone.utc).isoformat(),
                    "is_read": False
                }
                await manager.send_personal_message(json.dumps(response_data), receiver_id)
                # Echo back to sender (chat_id for sender is receiver_id)
                sender_echo = dict(response_data)
                sender_echo["chat_id"] = receiver_id
                await manager.send_personal_message(json.dumps(sender_echo), user.id)
                
    except WebSocketDisconnect:
        manager.disconnect(user.id)

