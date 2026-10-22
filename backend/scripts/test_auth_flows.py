"""
Backend Authentication Regression Test Suite
Tests all 4 authentication flows against the real MySQL database without external dependencies:
1. User Registration (end-to-end against MySQL)
2. User Login (Form URL-encoded & JSON simulation against MySQL)
3. Safe Guest Mode (JWT generation, is_guest flag, database persistence)
4. Google Sign-In endpoint validation & security
"""

import sys
import os
import time
import asyncio
from unittest.mock import AsyncMock

# Ensure backend directory is in python path
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, backend_dir)

from app.db.database import SessionLocal
from app.db.models import User
from app.core import security
from app.schemas.user import UserCreate
from app.api.routes.auth import register, login_access_token, guest_auth, google_auth, GoogleAuthRequest
from fastapi import HTTPException, Request

async def run_tests():
    print("=" * 65)
    print(" Running Backend Authentication Regression Tests Against MySQL")
    print("=" * 65)
    
    timestamp = int(time.time())
    test_email = f"mobile_test_user_{timestamp}@example.com"
    test_password = "SecurePassword123!"
    test_name = f"Mobile Tester {timestamp}"

    db = SessionLocal()
    try:
        # 1. Test Registration
        print("\n[Test 1] Testing User Registration against MySQL...")
        user_in = UserCreate(
            name=test_name,
            email=test_email,
            password=test_password,
            is_test_user=True,
        )
        created_user = register(user_in=user_in, db=db)
        assert created_user.id is not None, "Created user ID should not be None"
        assert created_user.email == test_email.lower(), "Email mismatch in registration"
        assert created_user.name == test_name, "Name mismatch in registration"
        print(f" -> Registration SUCCESS! User ID: {created_user.id}, Email: {created_user.email}")

        # Verify duplicate email prevention
        try:
            register(user_in=user_in, db=db)
            assert False, "Should have thrown HTTPException 400 for duplicate email"
        except HTTPException as e:
            assert e.status_code == 400, "Duplicate email did not return 400"
            print(" -> Duplicate email rejection verified (HTTP 400).")

        # 2. Test Login with Form URL-encoded Simulation
        print("\n[Test 2A] Testing Login with Form URL-encoded request...")
        mock_form_req = AsyncMock(spec=Request)
        mock_form_req.headers = {"content-type": "application/x-www-form-urlencoded"}
        mock_form_req.form = AsyncMock(return_value={"username": test_email, "password": test_password})
        mock_form_req.json = AsyncMock(side_effect=Exception("Not JSON"))

        form_login_token = await login_access_token(request=mock_form_req, db=db)
        assert "access_token" in form_login_token, "access_token missing in form login response"
        assert form_login_token["is_guest"] is False, "Regular login should not have is_guest=True"
        print(f" -> Form Login SUCCESS! Token: {form_login_token['access_token'][:25]}...")

        # 2B. Test Login with JSON Simulation
        print("\n[Test 2B] Testing Login with JSON request...")
        mock_json_req = AsyncMock(spec=Request)
        mock_json_req.headers = {"content-type": "application/json"}
        mock_json_req.form = AsyncMock(side_effect=Exception("Not Form"))
        mock_json_req.json = AsyncMock(return_value={"username": test_email, "password": test_password})

        json_login_token = await login_access_token(request=mock_json_req, db=db)
        assert "access_token" in json_login_token, "access_token missing in JSON login response"
        print(" -> JSON Login SUCCESS!")

        # 2C. Test Invalid Password Login
        print("\n[Test 2C] Testing Login with Wrong Password...")
        mock_fail_req = AsyncMock(spec=Request)
        mock_fail_req.headers = {"content-type": "application/json"}
        mock_fail_req.form = AsyncMock(side_effect=Exception("Not Form"))
        mock_fail_req.json = AsyncMock(return_value={"username": test_email, "password": "WrongPassword!"})
        try:
            await login_access_token(request=mock_fail_req, db=db)
            assert False, "Login with wrong password should fail"
        except HTTPException as e:
            assert e.status_code == 401, f"Expected 401 for wrong password, got {e.status_code}"
            print(" -> Invalid password rejection verified (HTTP 401).")

        # 3. Test Safe Guest Mode (/auth/guest)
        print("\n[Test 3] Testing Safe Guest Mode (/auth/guest)...")
        guest_token = guest_auth(db=db)
        assert "access_token" in guest_token, "access_token missing in guest response"
        assert guest_token["is_guest"] is True, "is_guest must be True for guest mode"
        
        # Verify guest user exists in MySQL
        guest_user = db.query(User).filter(User.email == "guest_user@localskillexchange.internal").first()
        assert guest_user is not None, "Guest user must exist in MySQL database"
        assert guest_user.is_test_user is True, "Guest user must have is_test_user=True"
        print(f" -> Guest Mode SUCCESS! User ID: {guest_user.id}, is_guest: True")

        # 4. Test Google Auth Endpoint Validation & Security
        print("\n[Test 4] Testing Google Auth endpoint validation & security...")
        # 4A: Missing id_token must be rejected
        try:
            await google_auth(request=GoogleAuthRequest(id_token=None, email=None), db=db)
            assert False, "Empty GoogleAuthRequest should be rejected"
        except HTTPException as e:
            assert e.status_code == 400, "Empty GoogleAuthRequest did not return 400"
            print(" -> Empty Google auth request rejected (HTTP 400).")

        # 4B: Unverified email without id_token must be rejected
        try:
            await google_auth(request=GoogleAuthRequest(id_token=None, email="attacker@example.com"), db=db)
            assert False, "Google auth without id_token should be rejected"
        except HTTPException as e:
            assert e.status_code == 400, "Unverified email without token did not return 400"
            print(" -> Unverified email without Google id_token rejected (HTTP 400).")

        # 4C: Invalid fake id_token must be rejected by Google tokeninfo
        try:
            await google_auth(request=GoogleAuthRequest(id_token="fake_invalid_token_xyz"), db=db)
            assert False, "Invalid Google id_token should be rejected"
        except HTTPException as e:
            assert e.status_code in (400, 502), f"Expected 400 or 502 for invalid Google token, got {e.status_code}"
            print(f" -> Invalid Google id_token rejected securely (HTTP {e.status_code}).")

        # 5. Clean up test user from MySQL
        print("\n[Cleanup] Cleaning up temporary test user...")
        user_to_delete = db.query(User).filter(User.email == test_email.lower()).first()
        if user_to_delete:
            db.delete(user_to_delete)
            db.commit()
            print(" -> Cleaned up test user from MySQL database.")

    finally:
        db.close()

    print("\n" + "=" * 65)
    print(" ALL 4 AUTHENTICATION FLOWS TESTED & VERIFIED AGAINST MYSQL!")
    print("=" * 65)

if __name__ == "__main__":
    asyncio.run(run_tests())
