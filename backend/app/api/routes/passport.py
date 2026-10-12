from fastapi import APIRouter, HTTPException, status

from ..deps import SessionDep, CurrentUser, OptionalCurrentUser
from ...schemas.passport import SkillPassportResponse
from ...services import passport_service
from ...db.models import User

router = APIRouter()

@router.get("/me", response_model=SkillPassportResponse)
def get_my_passport(db: SessionDep, user: CurrentUser):
    """
    Retrieve the complete, authenticated Skill Passport for the current user.
    Aggregates real MySQL learning, practice, certification, and exchange records.
    """
    passport = passport_service.get_skill_passport(db, user_id=user.id, is_public=False)
    if not passport:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User passport not found",
        )
    return passport

@router.get("/user/{user_id}", response_model=SkillPassportResponse)
@router.get("/{user_id}", response_model=SkillPassportResponse)
def get_user_public_passport(
    user_id: int,
    db: SessionDep,
    current_user: OptionalCurrentUser = None,
    include_test_users: bool = False,
):
    """
    Retrieve a safe, public Skill Passport view for a specific user.
    Excludes private data such as email, wallet credits spent, and private details.
    """
    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User passport not found")
    if target_user.is_test_user and not (current_user and (getattr(current_user, "is_test_user", False) or current_user.id == user_id)) and not include_test_users:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User passport not found")

    passport = passport_service.get_skill_passport(db, user_id=user_id, is_public=True)
    if not passport:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User passport not found",
        )
    return passport
