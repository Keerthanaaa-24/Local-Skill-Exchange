from fastapi import APIRouter, Depends, HTTPException, status
from typing import List

from ..deps import SessionDep, CurrentUser
from ...schemas.certificate import CertificateOut, CertificateVerifyOut
from ...services import certificate_service

router = APIRouter()

@router.get("/")
@router.get("", response_model=List[CertificateOut])
def list_my_certificates(db: SessionDep, user: CurrentUser):
    """Retrieve all certificates earned by the authenticated user."""
    return certificate_service.get_user_certificates(db, user.id)

@router.get("/verify/{verification_code}", response_model=CertificateVerifyOut)
def verify_certificate(verification_code: str, db: SessionDep):
    """Public verification endpoint for verifying certificate authenticity."""
    return certificate_service.verify_certificate_code(db, verification_code)

@router.get("/{certificate_id}", response_model=CertificateOut)
def get_certificate_detail(certificate_id: int, db: SessionDep, user: CurrentUser):
    """Retrieve a single certificate owned by the authenticated user."""
    return certificate_service.get_certificate_by_id(db, certificate_id, user.id)

@router.post("/issue/{learning_path_id}", response_model=CertificateOut)
def issue_certificate(learning_path_id: int, db: SessionDep, user: CurrentUser):
    """Issue a certificate upon 100% completion of all lessons in a path."""
    return certificate_service.verify_and_issue_certificate(db, user, learning_path_id)
