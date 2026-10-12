from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Any, Optional
from pydantic import BaseModel

from ..deps import SessionDep, CurrentUser
from ...db.models import Skill, UserSkillOffered, UserSkillWanted, User

router = APIRouter()

class SkillBase(BaseModel):
    name: Optional[str] = None
    title: Optional[str] = None
    category: Optional[str] = None
    category_name: Optional[str] = None

class SkillCreate(SkillBase):
    pass

class SkillUpdate(BaseModel):
    name: Optional[str] = None
    title: Optional[str] = None
    category: Optional[str] = None
    category_name: Optional[str] = None
    description: Optional[str] = None

class SkillResponse(BaseModel):
    id: int
    name: str
    category: str

    class Config:
        from_attributes = True

class SkillCatalogResponse(BaseModel):
    total: int
    page: int
    limit: int
    total_pages: int
    data: List[SkillResponse]

class CategoryCount(BaseModel):
    category: str
    count: int

class UserSkillsResponse(BaseModel):
    offered: List[dict]
    wanted: List[dict]

class UserSkillsUpdate(BaseModel):
    offered_skills: Optional[List[str]] = None
    wanted_skills: Optional[List[str]] = None

from ...services.category_normalizer import (
    normalize_category,
    build_category_filter_condition,
    get_test_skill_filter,
    get_category_counts
)

def _format_skill(skill: Skill, user: Optional[User] = None):
    primary_category = normalize_category(skill.category)
    tags = list(dict.fromkeys([primary_category, skill.category])) if skill.category else ["General"]
    if user:
        return {
            "id": skill.id,
            "title": skill.name,
            "name": skill.name,
            "description": f"Learn {skill.name} with {user.name}. Experienced mentor ready to help.",
            "category_name": primary_category,
            "category": primary_category,
            "domain": skill.category or primary_category,
            "owner_id": user.id,
            "owner_name": user.name,
            "owner_profile_image": user.avatar_url or "https://i.pravatar.cc/150",
            "image_url": f"https://picsum.photos/seed/{skill.id}/400/300",
            "credits": 10,
            "rating": user.rating or 5.0,
            "review_count": user.reviews or 0,
            "latitude": user.lat or 12.9716,
            "longitude": user.lng or 77.5946,
            "is_available": user.is_online,
            "tags": tags
        }
    else:
        return {
            "id": skill.id,
            "title": skill.name,
            "name": skill.name,
            "description": f"Master {skill.name} through local peer exchange sessions.",
            "category_name": primary_category,
            "category": primary_category,
            "domain": skill.category or primary_category,
            "owner_id": 1,
            "owner_name": "Community Mentor",
            "owner_profile_image": "https://i.pravatar.cc/150",
            "image_url": f"https://picsum.photos/seed/{skill.id}/400/300",
            "credits": 10,
            "rating": 5.0,
            "review_count": 12,
            "latitude": 12.9716,
            "longitude": 77.5946,
            "is_available": True,
            "tags": tags
        }

@router.get("/")
@router.get("")
def get_skills(
    db: SessionDep,
    page: int = 1,
    limit: int = 20,
    category: Optional[str] = None,
    categories: Optional[str] = None,
    q: Optional[str] = None
):
    query = db.query(Skill).filter(get_test_skill_filter(Skill))
    
    if q and q.strip():
        search_term = f"%{q.strip().lower()}%"
        query = query.filter(Skill.name.ilike(search_term) | Skill.category.ilike(search_term))

    cat_filter = categories or category
    if cat_filter and cat_filter.strip() and cat_filter.strip() != "All":
        cat_cond = build_category_filter_condition(Skill, cat_filter)
        if cat_cond is not None:
            query = query.filter(cat_cond)

    total = query.count()
    skills = query.order_by(Skill.id).offset((page - 1) * limit).limit(limit).all()

    # Map offered skills to real users
    skill_ids = [s.id for s in skills]
    offered_map = {}
    if skill_ids:
        offered_records = db.query(UserSkillOffered, User).join(User, UserSkillOffered.user_id == User.id).filter(UserSkillOffered.skill_id.in_(skill_ids), User.is_test_user == False).all()
        for uso, user in offered_records:
            if uso.skill_id not in offered_map:
                offered_map[uso.skill_id] = user

    formatted = [_format_skill(skill, offered_map.get(skill.id)) for skill in skills]
    return {"data": formatted, "total": total, "page": page, "limit": limit}

@router.get("/search")
def search_skills(db: SessionDep, q: str = "", category: Optional[str] = None, categories: Optional[str] = None):
    query = db.query(Skill).filter(get_test_skill_filter(Skill))
    q_lower = q.strip().lower()
    if q_lower:
        query = query.filter(
            Skill.name.ilike(f"%{q_lower}%") | Skill.category.ilike(f"%{q_lower}%")
        )
    cat_filter = categories or category
    if cat_filter and cat_filter.strip() and cat_filter.strip() != "All":
        cat_cond = build_category_filter_condition(Skill, cat_filter)
        if cat_cond is not None:
            query = query.filter(cat_cond)

    skills = query.limit(50).all()
    skill_ids = [s.id for s in skills]
    offered_map = {}
    if skill_ids:
        offered_records = db.query(UserSkillOffered, User).join(User, UserSkillOffered.user_id == User.id).filter(UserSkillOffered.skill_id.in_(skill_ids), User.is_test_user == False).all()
        for uso, user in offered_records:
            if uso.skill_id not in offered_map:
                offered_map[uso.skill_id] = user

    formatted = [_format_skill(skill, offered_map.get(skill.id)) for skill in skills]
    return {"data": formatted}

@router.get("/catalog", response_model=SkillCatalogResponse)
def get_skill_catalog(
    db: SessionDep,
    q: Optional[str] = Query(None, description="Search term"),
    category: Optional[str] = Query(None, description="Filter by category"),
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200)
):
    query = db.query(Skill).filter(get_test_skill_filter(Skill))
    if q and q.strip():
        search_term = f"%{q.strip().lower()}%"
        query = query.filter(Skill.name.ilike(search_term))
    if category and category.strip() and category.strip() != "All":
        cat_cond = build_category_filter_condition(Skill, category)
        if cat_cond is not None:
            query = query.filter(cat_cond)

    total = query.count()
    offset = (page - 1) * limit
    skills = query.order_by(Skill.category, Skill.name).offset(offset).limit(limit).all()
    total_pages = (total + limit - 1) // limit if total > 0 else 1

    return {
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": total_pages,
        "data": skills
    }

@router.get("/categories", response_model=List[CategoryCount])
def get_skill_categories(db: SessionDep):
    counts = get_category_counts(db, Skill)
    return counts

@router.get("/my-skills", response_model=UserSkillsResponse)
def get_my_skills(db: SessionDep, current_user: CurrentUser):
    offered = [
        {"id": uso.skill.id, "name": uso.skill.name, "category": uso.skill.category}
        for uso in current_user.skills_offered if uso.skill
    ]
    wanted = [
        {"id": usw.skill.id, "name": usw.skill.name, "category": usw.skill.category}
        for usw in current_user.skills_wanted if usw.skill
    ]
    return {"offered": offered, "wanted": wanted}

@router.post("/my-skills")
def sync_my_skills(skills_in: UserSkillsUpdate, db: SessionDep, current_user: CurrentUser):
    if skills_in.offered_skills is not None:
        # Clear existing offered skills and replace
        db.query(UserSkillOffered).filter(UserSkillOffered.user_id == current_user.id).delete(synchronize_session=False)
        for skill_name in skills_in.offered_skills:
            sname = skill_name.strip()
            if not sname:
                continue
            skill = db.query(Skill).filter(Skill.name.ilike(sname)).first()
            if not skill:
                skill = Skill(name=sname, category="General")
                db.add(skill)
                db.flush()
            db.add(UserSkillOffered(user_id=current_user.id, skill_id=skill.id))

    if skills_in.wanted_skills is not None:
        db.query(UserSkillWanted).filter(UserSkillWanted.user_id == current_user.id).delete(synchronize_session=False)
        for skill_name in skills_in.wanted_skills:
            sname = skill_name.strip()
            if not sname:
                continue
            skill = db.query(Skill).filter(Skill.name.ilike(sname)).first()
            if not skill:
                skill = Skill(name=sname, category="General")
                db.add(skill)
                db.flush()
            db.add(UserSkillWanted(user_id=current_user.id, skill_id=skill.id))

    db.commit()
    return {"message": "Skills updated successfully"}

@router.get("/category/{category_name}")
def get_skills_by_category(db: SessionDep, category_name: str):
    cat_cond = build_category_filter_condition(Skill, category_name)
    query = db.query(Skill).filter(get_test_skill_filter(Skill))
    if cat_cond is not None:
        query = query.filter(cat_cond)
    skills = query.limit(100).all()
    skill_ids = [s.id for s in skills]
    offered_map = {}
    if skill_ids:
        offered_records = db.query(UserSkillOffered, User).join(User, UserSkillOffered.user_id == User.id).filter(UserSkillOffered.skill_id.in_(skill_ids), User.is_test_user == False).all()
        for uso, user in offered_records:
            if uso.skill_id not in offered_map:
                offered_map[uso.skill_id] = user

    formatted = [_format_skill(skill, offered_map.get(skill.id)) for skill in skills]
    return {"data": formatted}

@router.get("/{skill_id}")
def get_skill_by_id(skill_id: int, db: SessionDep):
    result = db.query(UserSkillOffered, User, Skill).join(User, UserSkillOffered.user_id == User.id).join(Skill, UserSkillOffered.skill_id == Skill.id).filter(Skill.id == skill_id).first()
    if not result:
        skill = db.query(Skill).filter(Skill.id == skill_id).first()
        if not skill:
            raise HTTPException(status_code=404, detail="Skill not found")
        return _format_skill(skill, None)
    
    _, user, skill = result
    return _format_skill(skill, user)

@router.post("/")
@router.post("")
def create_skill(skill_in: SkillCreate, db: SessionDep, current_user: CurrentUser):
    raw_name = (skill_in.name or skill_in.title or "").strip()
    raw_cat = (skill_in.category or skill_in.category_name or "General").strip()
    if not raw_name:
        raise HTTPException(status_code=400, detail="Skill name or title is required")

    skill = db.query(Skill).filter(Skill.name == raw_name).first()
    if not skill:
        skill = Skill(name=raw_name, category=raw_cat)
        db.add(skill)
        db.commit()
        db.refresh(skill)

    # Automatically add to offered skills for creator
    existing_offered = db.query(UserSkillOffered).filter(
        UserSkillOffered.user_id == current_user.id,
        UserSkillOffered.skill_id == skill.id
    ).first()
    if not existing_offered:
        db.add(UserSkillOffered(user_id=current_user.id, skill_id=skill.id))
        db.commit()

    return {
        "id": skill.id,
        "name": skill.name,
        "title": skill.name,
        "category": skill.category,
        "category_name": skill.category,
        "owner_id": current_user.id,
        "owner_name": current_user.name,
        "owner_profile_image": current_user.avatar_url,
        "image_url": f"https://picsum.photos/seed/{skill.id}/400/300",
        "credits": 10,
        "rating": current_user.rating or 5.0,
        "review_count": current_user.reviews or 0,
        "is_available": True,
        "message": "Skill created successfully"
    }

@router.patch("/{skill_id}")
@router.put("/{skill_id}")
def update_skill(skill_id: int, skill_in: SkillUpdate, db: SessionDep, current_user: CurrentUser):
    skill = db.query(Skill).filter(Skill.id == skill_id).first()
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")

    new_name = (skill_in.name or skill_in.title)
    new_cat = (skill_in.category or skill_in.category_name)
    if new_name:
        skill.name = new_name.strip()
    if new_cat:
        skill.category = new_cat.strip()

    db.commit()
    db.refresh(skill)
    return {"message": "Skill updated successfully", "id": skill.id, "name": skill.name, "category": skill.category}

@router.delete("/{skill_id}")
def delete_skill(skill_id: int, db: SessionDep, current_user: CurrentUser):
    # Remove from offered skills
    db.query(UserSkillOffered).filter(
        UserSkillOffered.user_id == current_user.id,
        UserSkillOffered.skill_id == skill_id
    ).delete(synchronize_session=False)
    # Remove from wanted skills
    db.query(UserSkillWanted).filter(
        UserSkillWanted.user_id == current_user.id,
        UserSkillWanted.skill_id == skill_id
    ).delete(synchronize_session=False)
    db.commit()
    return {"message": "Skill removed successfully"}

@router.post("/{skill_id}/offer")
@router.post("/offer/{skill_id}")
def offer_skill(skill_id: int, db: SessionDep, current_user: CurrentUser):
    skill = db.query(Skill).filter(Skill.id == skill_id).first()
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")
    
    existing = db.query(UserSkillOffered).filter(
        UserSkillOffered.user_id == current_user.id,
        UserSkillOffered.skill_id == skill_id
    ).first()
    
    if not existing:
        user_skill = UserSkillOffered(user_id=current_user.id, skill_id=skill_id)
        db.add(user_skill)
        db.commit()
    return {"message": "Skill added to offered"}

@router.post("/{skill_id}/request")
@router.post("/{skill_id}/want")
@router.post("/want/{skill_id}")
def want_skill(skill_id: int, db: SessionDep, current_user: CurrentUser):
    skill = db.query(Skill).filter(Skill.id == skill_id).first()
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")
    
    existing = db.query(UserSkillWanted).filter(
        UserSkillWanted.user_id == current_user.id,
        UserSkillWanted.skill_id == skill_id
    ).first()
    
    if not existing:
        user_skill = UserSkillWanted(user_id=current_user.id, skill_id=skill_id)
        db.add(user_skill)
        db.commit()
    return {"message": "Skill added to wanted"}
