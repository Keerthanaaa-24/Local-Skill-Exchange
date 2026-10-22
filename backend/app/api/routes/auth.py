from fastapi import APIRouter, Depends, HTTPException, Request, status
from typing import Optional
from pydantic import BaseModel
from sqlalchemy import func

from ...core import security
from ...core.config import settings
from ...db.models import User
from ...schemas.user import UserCreate, UserResponse
from ...schemas.token import Token
from ..deps import SessionDep

router = APIRouter()

@router.post("/register", response_model=UserResponse)
def register(user_in: UserCreate, db: SessionDep):
    clean_email = user_in.email.strip().lower()
    user = db.query(User).filter(func.lower(User.email) == clean_email).first()
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this email already exists in the system.",
        )
    
    # Auto-classify test accounts by flag or common test patterns
    is_test = False
    if user_in.is_test_user:
        is_test = True
    elif (
        clean_email.endswith("@example.com")
        or clean_email.endswith("@test.com")
        or clean_email.startswith(("test_", "testuser", "audit_user_", "e2e_test_", "phase_o_user_", "aicoach_"))
        or "tester" in user_in.name.lower()
    ):
        is_test = True

    user = User(
        email=clean_email,
        name=user_in.name.strip(),
        hashed_password=security.get_password_hash(user_in.password),
        is_test_user=is_test,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.post("/login", response_model=Token)
async def login_access_token(request: Request, db: SessionDep):
    username_val = None
    password_val = None

    content_type = request.headers.get("content-type", "")

    # 1. Try form data if header suggests form or multipart
    if "application/x-www-form-urlencoded" in content_type or "multipart/form-data" in content_type:
        try:
            form = await request.form()
            username_val = form.get("username") or form.get("email")
            password_val = form.get("password")
        except Exception:
            pass

    # 2. Try JSON body if header suggests JSON or form parsing returned nothing
    if not username_val or not password_val:
        try:
            body = await request.json()
            if isinstance(body, dict):
                username_val = body.get("username") or body.get("email")
                password_val = body.get("password")
        except Exception:
            pass

    # 3. Fallback form attempt
    if not username_val or not password_val:
        try:
            form = await request.form()
            username_val = form.get("username") or form.get("email")
            password_val = form.get("password")
        except Exception:
            pass

    if not username_val or not password_val:
        raise HTTPException(status_code=400, detail="Username/email and password required")

    clean_username = str(username_val).strip().lower()
    user = db.query(User).filter(func.lower(User.email) == clean_username).first()
    if not user or not security.verify_password(password_val, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    
    access_token = security.create_access_token(user.id)
    return {"access_token": access_token, "token_type": "bearer", "is_guest": False}

class GoogleAuthRequest(BaseModel):
    id_token: Optional[str] = None
    access_token: Optional[str] = None
    email: Optional[str] = None
    name: Optional[str] = None
    avatar_url: Optional[str] = None

import json
import logging
import secrets
import urllib.request
import urllib.error

logger = logging.getLogger(__name__)

def verify_google_id_token(id_token: str) -> dict:
    url = f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "FastAPI-Auth"})
        with urllib.request.urlopen(req, timeout=7) as response:
            if response.status == 200:
                data = json.loads(response.read().decode("utf-8"))
                client_id = getattr(settings, "GOOGLE_CLIENT_ID", "") or os.getenv("GOOGLE_CLIENT_ID", "")
                if client_id and data.get("aud") != client_id:
                    logger.error(f"Google token aud mismatch: {data.get('aud')} != {client_id}")
                    raise HTTPException(status_code=400, detail="Google token audience mismatch")
                return data
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8")
        logger.error(f"Google token verification failed: {err_msg}")
        raise HTTPException(status_code=400, detail="Invalid Google ID token")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error contacting Google OAuth servers: {e}")
        raise HTTPException(status_code=502, detail="Failed to connect to Google OAuth servers")
    raise HTTPException(status_code=400, detail="Google token verification failed")

@router.post("/google", response_model=Token)
async def google_auth(request: GoogleAuthRequest, db: SessionDep):
    if not request.id_token or not request.id_token.strip():
        raise HTTPException(status_code=400, detail="Google id_token is required for authentication")
    
    token_info = verify_google_id_token(request.id_token.strip())
    verified_email = token_info.get("email")
    if not verified_email:
        raise HTTPException(status_code=400, detail="Google token missing verified email")
    verified_name = token_info.get("name") or request.name or verified_email.split("@")[0]
    avatar = token_info.get("picture") or request.avatar_url or ""

    clean_email = verified_email.strip().lower()
    user = db.query(User).filter(func.lower(User.email) == clean_email).first()
    if not user:
        user = User(
            email=clean_email,
            name=verified_name,
            avatar_url=avatar,
            hashed_password=security.get_password_hash(secrets.token_urlsafe(32)),
            is_test_user=False,
            title="Community Member",
            credits=100,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    elif avatar and not user.avatar_url:
        user.avatar_url = avatar
        db.commit()
        db.refresh(user)

    access_token = security.create_access_token(user.id)
    return {"access_token": access_token, "token_type": "bearer", "is_guest": False}

@router.post("/guest", response_model=Token)
def guest_auth(db: SessionDep):
    guest_email = "guest_user@localskillexchange.internal"
    user = db.query(User).filter(func.lower(User.email) == guest_email).first()
    if not user:
        user = User(
            email=guest_email,
            name="Guest Explorer",
            hashed_password=security.get_password_hash(secrets.token_urlsafe(32)),
            is_test_user=True,
            title="Guest Visitor",
            credits=100,
            avatar_url="",
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    
    access_token = security.create_access_token(user.id)
    return {"access_token": access_token, "token_type": "bearer", "is_guest": True}

