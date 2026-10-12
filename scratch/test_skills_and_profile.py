import os
import sys
import json
import time
import random
import urllib.request
import urllib.parse

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

BASE_URL = "http://127.0.0.1:8000/api/v1"

def http_request(url, method="GET", headers=None, data=None, form_data=None):
    if headers is None:
        headers = {}
    encoded_data = None
    if form_data:
        encoded_data = urllib.parse.urlencode(form_data).encode("utf-8")
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    elif data is not None:
        encoded_data = json.dumps(data).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(url, data=encoded_data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as response:
            body = response.read().decode("utf-8")
            status = response.status
            return status, json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            parsed = json.loads(body)
        except Exception:
            parsed = {"raw": body}
        return e.code, parsed

def test_all():
    print("=== Testing Skills Catalog, Profile Update & Upcoming Bookings ===")

    # 1. Register & Login dynamic test users
    uid1 = f"test_{int(time.time())}_{random.randint(100,999)}"
    email1 = f"{uid1}@example.com"
    reg1_status, reg1_data = http_request(f"{BASE_URL}/auth/register", method="POST", data={
        "email": email1,
        "name": "Alex Skill Learner",
        "password": "password123"
    })
    assert reg1_status in [200, 201], f"Register failed: {reg1_data}"
    
    status, login_res = http_request(f"{BASE_URL}/auth/login", method="POST", form_data={"username": email1, "password": "password123"})
    if status != 200:
        status, login_res = http_request(f"{BASE_URL}/auth/login", method="POST", data={"email": email1, "password": "password123"})
    
    assert status == 200, f"Login failed: {login_res}"
    token = login_res["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print("✓ Auth register & login successful")

    # 2. Test Skills Catalog
    status, cat_data = http_request(f"{BASE_URL}/skills/catalog?page=1&limit=20")
    assert status == 200, f"Catalog failed: {cat_data}"
    assert cat_data["total"] >= 1500, f"Expected >= 1500 skills, got {cat_data['total']}"
    assert len(cat_data["data"]) == 20
    print(f"✓ Skills catalog returned {cat_data['total']} total skills across {cat_data['total_pages']} pages")

    # 3. Test Search in Catalog
    status, search_data = http_request(f"{BASE_URL}/skills/catalog?q=python")
    assert status == 200
    assert search_data["total"] > 0
    assert any("python" in s["name"].lower() for s in search_data["data"])
    print(f"✓ Skills catalog search for 'python' matched {search_data['total']} skills")

    # 4. Test Categories
    status, categories = http_request(f"{BASE_URL}/skills/categories")
    assert status == 200
    assert len(categories) >= 20, f"Expected >= 20 categories, got {len(categories)}"
    print(f"✓ Skills categories endpoint returned {len(categories)} categories")

    # 5. Test Update Profile with Offered & Wanted Skills
    status, up_data = http_request(
        f"{BASE_URL}/users/me",
        method="PUT",
        headers=headers,
        data={
            "name": "Alex User",
            "bio": "Senior Full-Stack Developer & Mentor",
            "lat": 12.9716,
            "lng": 77.5946,
            "skills": ["Python", "FastAPI", "Flutter Development"],
            "wanted_skills": ["Machine Learning", "Guitar", "French for Beginners & Travelers"]
        }
    )
    assert status == 200, f"Update profile failed: {up_data}"
    assert up_data["name"] == "Alex User"
    assert "profile" in up_data
    assert len(up_data["profile"]["skills"]) >= 2
    assert len(up_data["profile"]["wanted_skills"]) >= 2
    print("✓ Profile update with offered/wanted skills & coordinates passed")

    # 6. Test GET /users/me verification
    status, me_data = http_request(f"{BASE_URL}/users/me", headers=headers)
    assert status == 200
    assert me_data["name"] == "Alex User"
    assert me_data["lat"] == 12.9716
    assert me_data["lng"] == 77.5946
    print("✓ GET /users/me returned refreshed profile data")

    # 7. Test User Skills Sync
    status, my_skills = http_request(f"{BASE_URL}/skills/my-skills", headers=headers)
    assert status == 200
    assert len(my_skills["offered"]) >= 2
    assert len(my_skills["wanted"]) >= 2
    print(f"✓ GET /skills/my-skills verified: {len(my_skills['offered'])} offered, {len(my_skills['wanted'])} wanted")

    # 8. Test Booking Creation & Upcoming Sessions Listing
    # Create mentor user
    uid2 = f"mentor_{int(time.time())}_{random.randint(100,999)}"
    email2 = f"{uid2}@example.com"
    http_request(f"{BASE_URL}/auth/register", method="POST", data={
        "email": email2,
        "name": "Mentor Master",
        "password": "password123"
    })
    _, login_u2 = http_request(f"{BASE_URL}/auth/login", method="POST", form_data={"username": email2, "password": "password123"})
    u2_token = login_u2["access_token"]
    _, u2_me = http_request(f"{BASE_URL}/users/me", headers={"Authorization": f"Bearer {u2_token}"})
    mentor_id = u2_me["id"]
    
    # Book a session with mentor
    b_status, created_booking = http_request(
        f"{BASE_URL}/bookings/",
        method="POST",
        headers=headers,
        data={
            "mentor_id": mentor_id,
            "skill_id": 1,
            "booking_date": "2026-10-15",
            "booking_time": "14:00",
            "location": "Google Meet",
            "credits_cost": 10
        }
    )
    assert b_status in [200, 201], f"Create booking failed: {created_booking}"
    print(f"✓ Booking created with ID {created_booking['id']}, status: {created_booking['status']}")
    assert created_booking["status"] == "upcoming"
    assert created_booking["mentor_name"] is not None
    assert created_booking["learner_name"] is not None
    assert created_booking["skill_title"] is not None

    # Check GET /bookings/upcoming for mentee
    up_status, upcoming_list = http_request(f"{BASE_URL}/bookings/upcoming", headers=headers)
    assert up_status == 200
    assert len(upcoming_list) > 0, "Expected at least 1 upcoming booking"
    sample = upcoming_list[0]
    assert sample["status"] in ["upcoming", "pending", "accepted"]
    assert sample["mentor_name"] is not None
    assert sample["learner_name"] is not None
    assert sample["skill_title"] is not None
    print(f"✓ GET /bookings/upcoming verified: {len(upcoming_list)} upcoming sessions with formatted names & titles")

    # Check GET /bookings/upcoming for mentor as well
    up_status2, mentor_upcoming = http_request(f"{BASE_URL}/bookings/upcoming", headers={"Authorization": f"Bearer {u2_token}"})
    assert up_status2 == 200
    assert len(mentor_upcoming) > 0
    assert mentor_upcoming[0]["mentor_name"] == "Mentor Master"
    assert mentor_upcoming[0]["learner_name"] == "Alex User"
    print(f"✓ Mentor upcoming bookings view verified: Learner '{mentor_upcoming[0]['learner_name']}', Mentor '{mentor_upcoming[0]['mentor_name']}'")

    print("\nALL SKILL CATALOG, PROFILE & BOOKING VERIFICATION TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    test_all()
