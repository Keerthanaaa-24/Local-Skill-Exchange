import urllib.request
import urllib.error
import json
import sys

BASE_URL = "http://127.0.0.1:8000/api/v1"

def test_guest_auth():
    print("[TEST] 1. POST /auth/guest...")
    req = urllib.request.Request(f"{BASE_URL}/auth/guest", data=b"", headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200, f"Expected 200, got {resp.status}"
        data = json.loads(resp.read().decode())
        assert "access_token" in data
        assert data.get("is_guest") is True
        token = data["access_token"]
        print("  [PASS] Received guest token.")

    # Check /users/me with guest token
    print("[TEST] 2. GET /users/me with guest token...")
    me_req = urllib.request.Request(f"{BASE_URL}/users/me", headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(me_req) as resp:
        assert resp.status == 200
        me_data = json.loads(resp.read().decode())
        assert me_data["email"] == "guest_user@localskillexchange.internal"
        assert me_data["name"] == "Guest Explorer"
        print(f"  [PASS] Verified guest profile: {me_data['name']} ({me_data['email']})")

    # Check booking restriction
    print("[TEST] 3. Verify guest booking restriction (403)...")
    book_payload = json.dumps({
        "mentor_id": 1,
        "skill_id": 1,
        "date": "2026-10-25",
        "location": "Online",
        "credits_cost": 50
    }).encode()
    book_req = urllib.request.Request(f"{BASE_URL}/bookings", data=book_payload, headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    })
    try:
        urllib.request.urlopen(book_req)
        assert False, "Guest booking should have failed with 403!"
    except urllib.error.HTTPError as e:
        assert e.code == 403, f"Expected 403, got {e.code}"
        print("  [PASS] Guest booking safely rejected with 403.")

def test_google_auth():
    print("[TEST] 4. Verify Google Auth rejects invalid token...")
    invalid_payload = json.dumps({"id_token": "invalid_test_token"}).encode()
    inv_req = urllib.request.Request(f"{BASE_URL}/auth/google", data=invalid_payload, headers={"Content-Type": "application/json"})
    try:
        urllib.request.urlopen(inv_req)
        assert False, "Invalid token should have been rejected!"
    except urllib.error.HTTPError as e:
        assert e.code == 400 or e.code == 401, f"Expected 400/401, got {e.code}"
        print(f"  [PASS] Invalid Google token honestly rejected ({e.code}).")

    print("[TEST] 5. Verify Google Auth accepts verified email payload...")
    valid_payload = json.dumps({
        "email": "autotest_google@example.com",
        "name": "Auto Google User",
        "avatar_url": "https://example.com/avatar.png"
    }).encode()
    val_req = urllib.request.Request(f"{BASE_URL}/auth/google", data=valid_payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(val_req) as resp:
        assert resp.status == 200
        data = json.loads(resp.read().decode())
        assert "access_token" in data
        g_token = data["access_token"]
        print("  [PASS] Google user authenticated and JWT returned.")

    me_req = urllib.request.Request(f"{BASE_URL}/users/me", headers={"Authorization": f"Bearer {g_token}"})
    with urllib.request.urlopen(me_req) as resp:
        me = json.loads(resp.read().decode())
        assert me["email"] == "autotest_google@example.com"
        print(f"  [PASS] Google user profile verified in MySQL: ID {me['id']}")

    # Clean up test user
    from backend.app.db.database import SessionLocal
    from backend.app.db.models import User
    db = SessionLocal()
    u = db.query(User).filter(User.email == "autotest_google@example.com").first()
    if u:
        db.delete(u)
        db.commit()
    db.close()
    print("  [PASS] Cleaned up temporary test user.")

if __name__ == "__main__":
    test_guest_auth()
    test_google_auth()
    print("\nALL AUTH FLOW TESTS PASSED SUCCESSFULLY!")
