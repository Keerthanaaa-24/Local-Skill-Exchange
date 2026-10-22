from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Request, Query
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
import uuid

from ...schemas.user import UserResponse
from ..deps import CurrentUser, OptionalCurrentUser, SessionDep
from ...db.models import User, Skill, UserSkillOffered, UserSkillWanted
from ...core import security
from ...utils.location import haversine

router = APIRouter()

class UserUpdate(BaseModel):
    name: Optional[str] = None
    title: Optional[str] = None
    bio: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    profile_image_url: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    skills: Optional[List[str]] = None
    offered_skills: Optional[List[str]] = None
    skills_offered: Optional[List[str]] = None
    wanted_skills: Optional[List[str]] = None
    skills_wanted: Optional[List[str]] = None

class PasswordChange(BaseModel):
    current_password: str
    new_password: str

@router.get("/me", response_model=UserResponse)
def read_user_me(current_user: CurrentUser):
    return current_user

@router.put("/me")
@router.patch("/me")
def update_user_me(user_in: UserUpdate, db: SessionDep, current_user: CurrentUser):
    if user_in.name is not None and user_in.name.strip():
        current_user.name = user_in.name.strip()
    if user_in.title is not None and user_in.title.strip():
        current_user.title = user_in.title.strip()
    elif user_in.bio is not None and user_in.bio.strip():
        current_user.title = user_in.bio.strip()
    if user_in.avatar_url is not None and user_in.avatar_url.strip():
        current_user.avatar_url = user_in.avatar_url.strip()
    elif user_in.profile_image_url is not None and user_in.profile_image_url.strip():
        current_user.avatar_url = user_in.profile_image_url.strip()
    if user_in.lat is not None:
        current_user.lat = user_in.lat
    if user_in.lng is not None:
        current_user.lng = user_in.lng

    # Sync offered skills
    offered = user_in.offered_skills or user_in.skills or user_in.skills_offered
    if offered is not None:
        db.query(UserSkillOffered).filter(UserSkillOffered.user_id == current_user.id).delete(synchronize_session=False)
        for sname in offered:
            clean = sname.strip()
            if not clean:
                continue
            skill = db.query(Skill).filter(Skill.name.ilike(clean)).first()
            if not skill:
                skill = Skill(name=clean, category="General")
                db.add(skill)
                db.flush()
            db.add(UserSkillOffered(user_id=current_user.id, skill_id=skill.id))

    # Sync wanted skills
    wanted = user_in.wanted_skills or user_in.skills_wanted
    if wanted is not None:
        db.query(UserSkillWanted).filter(UserSkillWanted.user_id == current_user.id).delete(synchronize_session=False)
        for sname in wanted:
            clean = sname.strip()
            if not clean:
                continue
            skill = db.query(Skill).filter(Skill.name.ilike(clean)).first()
            if not skill:
                skill = Skill(name=clean, category="General")
                db.add(skill)
                db.flush()
            db.add(UserSkillWanted(user_id=current_user.id, skill_id=skill.id))

    db.commit()
    db.refresh(current_user)
    
    # Return structure compatible with both UserResponse and UpdateProfileResponse
    return {
        "id": current_user.id,
        "email": current_user.email,
        "name": current_user.name,
        "title": current_user.title,
        "avatar_url": current_user.avatar_url,
        "rating": current_user.rating,
        "reviews": current_user.reviews,
        "xp": current_user.xp,
        "credits": current_user.credits,
        "streak_days": current_user.streak_days,
        "is_online": current_user.is_online,
        "is_admin": current_user.is_admin,
        "lat": current_user.lat,
        "lng": current_user.lng,
        "created_at": current_user.created_at.isoformat() if current_user.created_at else None,
        "message": "Profile updated successfully",
        "profile": {
            "id": str(current_user.id),
            "email": current_user.email,
            "name": current_user.name,
            "bio": current_user.title,
            "phone": user_in.phone,
            "profile_image_url": current_user.avatar_url,
            "credits": current_user.credits or 0,
            "rating": current_user.rating or 5.0,
            "review_count": current_user.reviews or 0,
            "skills": [s.skill.name for s in current_user.skills_offered if s.skill] if current_user.skills_offered else [],
            "wanted_skills": [s.skill.name for s in current_user.skills_wanted if s.skill] if current_user.skills_wanted else [],
        }
    }

@router.post("/me/password")
def change_password(pass_in: PasswordChange, db: SessionDep, current_user: CurrentUser):
    if not security.verify_password(pass_in.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect current password")
    if len(pass_in.new_password) < 6:
        raise HTTPException(status_code=400, detail="New password must be at least 6 characters long")
    
    current_user.hashed_password = security.get_password_hash(pass_in.new_password)
    db.commit()
    return {"message": "Password changed successfully"}

@router.post("/me/image")
async def upload_user_image(
    request: Request,
    db: SessionDep,
    current_user: CurrentUser,
):
    if current_user.email == "guest_user@localskillexchange.internal":
        raise HTTPException(status_code=403, detail="Guests cannot upload avatars. Please register or log in.")

    # 1. Enforce 5 MB maximum before processing
    MAX_AVATAR_BYTES = 5 * 1024 * 1024  # 5 MB ceiling
    content_length = request.headers.get("content-length")
    if content_length:
        try:
            if int(content_length) > MAX_AVATAR_BYTES:
                raise HTTPException(status_code=413, detail="File too large. Maximum avatar size is 5 MB.")
        except ValueError:
            pass

    form = await request.form()
    file = form.get("file") or form.get("image")
    if not file or not hasattr(file, "read"):
        raise HTTPException(status_code=400, detail="No image file provided in request.")

    # 2. Bounded stream read (read at most MAX_AVATAR_BYTES + 1 to prevent memory exhaustion)
    content = await file.read(MAX_AVATAR_BYTES + 1)
    if not content or len(content) == 0:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")

    if len(content) > MAX_AVATAR_BYTES:
        raise HTTPException(status_code=413, detail="File too large. Maximum avatar size is 5 MB.")

    # 3. Content-signature (magic bytes) validation
    if content.startswith(b"\xff\xd8\xff"):
        verified_ext = ".jpg"
    elif content.startswith(b"\x89PNG\r\n\x1a\n"):
        verified_ext = ".png"
    elif len(content) >= 12 and content[0:4] == b"RIFF" and content[8:12] == b"WEBP":
        verified_ext = ".webp"
    elif content.startswith((b"GIF87a", b"GIF89a")):
        verified_ext = ".gif"
    else:
        raise HTTPException(
            status_code=400,
            detail="Invalid image format. Supported formats are JPEG, PNG, WebP, and GIF.",
        )

    # 4. Deep structural image-decoding validation via Pillow
    import io
    try:
        from PIL import Image
        img = Image.open(io.BytesIO(content))
        img.verify()
        if img.format not in ("JPEG", "PNG", "WEBP", "GIF"):
            raise HTTPException(status_code=400, detail="Image decoding failed: unsupported image format.")
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=400, detail="Image decoding validation failed: corrupt image data.")

    import os, uuid
    upload_dir = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))),
        "uploads",
        "avatars",
    )
    os.makedirs(upload_dir, exist_ok=True)
    filename = f"avatar_{current_user.id}_{uuid.uuid4().hex[:12]}{verified_ext}"
    filepath = os.path.join(upload_dir, filename)

    with open(filepath, "wb") as f:
        f.write(content)

    avatar_url = f"/uploads/avatars/{filename}"
    current_user.avatar_url = avatar_url
    db.commit()
    db.refresh(current_user)
    return {"profile_image_url": avatar_url, "avatar_url": avatar_url}

@router.get("/nearby", response_model=List[UserResponse])
def get_nearby_users(
    db: SessionDep,
    current_user: OptionalCurrentUser = None,
    radius_km: float = 50.0,
    include_test_users: bool = False,
    skill: Optional[str] = Query(None),
    q: Optional[str] = Query(None),
    query: Optional[str] = Query(None),
    category: Optional[str] = Query(None),
    min_rating: Optional[float] = Query(None),
    is_online: Optional[bool] = Query(None),
):
    search_str = (skill or q or query or "").strip().lower()

    db_query = db.query(User)
    if not include_test_users or str(include_test_users).lower() in ("false", "0"):
        db_query = db_query.filter(User.is_test_user == False)
    if current_user:
        db_query = db_query.filter(User.id != current_user.id)
    if is_online is True or (is_online is not None and str(is_online).lower() in ("true", "1")):
        db_query = db_query.filter(User.is_online == True)
    if min_rating is not None and min_rating > 0:
        db_query = db_query.filter(User.rating >= min_rating)

    all_users = db_query.all()

    nearby = []
    for u in all_users:
        # Check text search matching if search_str is provided
        if search_str:
            offered_names = [s.skill.name.lower() for s in u.skills_offered if s.skill and s.skill.name]
            wanted_names = [s.skill.name.lower() for s in u.skills_wanted if s.skill and s.skill.name]
            name_match = search_str in u.name.lower()
            title_match = search_str in (u.title or "").lower()
            offered_match = any(search_str in sname for sname in offered_names)
            wanted_match = any(search_str in sname for sname in wanted_names)

            if not (name_match or title_match or offered_match or wanted_match):
                continue

        # Check category matching if category is provided
        if category and category.lower() != "all":
            cat_str = category.lower()
            offered_cats = [s.skill.category.lower() for s in u.skills_offered if s.skill and s.skill.category]
            if not any(cat_str in c for c in offered_cats):
                # allow category string matching on title as fallback
                if cat_str not in (u.title or "").lower():
                    continue

        # Distance calculation
        dist = None
        if current_user and current_user.lat is not None and current_user.lng is not None and u.lat is not None and u.lng is not None:
            dist = haversine(current_user.lat, current_user.lng, u.lat, u.lng)
            u.distance_km = round(dist, 1)
        elif u.lat is not None and u.lng is not None:
            u.distance_km = 2.5
        else:
            u.distance_km = None

        if radius_km < 100 and dist is not None and dist > radius_km:
            continue

        nearby.append(u)

    return nearby

@router.get("/{user_id}", response_model=UserResponse)
def get_user_by_id(user_id: int, db: SessionDep, current_user: OptionalCurrentUser = None):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.is_test_user:
        if not current_user or not getattr(current_user, "is_test_user", False):
            raise HTTPException(status_code=404, detail="Mentor profile not available")
    return user

