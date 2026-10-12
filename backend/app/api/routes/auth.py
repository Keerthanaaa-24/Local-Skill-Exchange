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
    return {"access_token": access_token, "token_type": "bearer"}

