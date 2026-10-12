import urllib.request
import urllib.parse
import json
import sys
import time
import random
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

BASE_URL = "http://127.0.0.1:8000/api/v1"

def make_req(url, token=None, method="GET", body=None):
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as res:
            resp_body = res.read().decode("utf-8")
            return res.status, json.loads(resp_body) if resp_body else {}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        print(f"HTTP Error {e.code} on {url}: {err_body}")
        raise

def create_and_login_user(name_prefix="NotifUser"):
    email = f"{name_prefix.lower()}_{int(time.time())}_{random.randint(100,999)}@example.com"
    password = "Password123!"
    reg_data = json.dumps({"name": f"{name_prefix} Test", "email": email, "password": password}).encode("utf-8")
    req = urllib.request.Request(f"{BASE_URL}/auth/register", data=reg_data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as res:
        user_info = json.loads(res.read().decode())
    
    login_data = urllib.parse.urlencode({"username": email, "password": password}).encode("utf-8")
    req2 = urllib.request.Request(f"{BASE_URL}/auth/login", data=login_data, headers={"Content-Type": "application/x-www-form-urlencoded"})
    with urllib.request.urlopen(req2) as res2:
        token_info = json.loads(res2.read().decode())
        return user_info, token_info["access_token"]

def run_notifications_e2e_tests():
    print("==================================================================")
    print(">>> RUNNING DYNAMIC REAL-TIME NOTIFICATION (PHASE 3) E2E SUITE <<<")
    print("==================================================================")

    # Create two test users (User A: Learner, User B: Mentor)
    user_a, token_a = create_and_login_user("LearnerA")
    user_b, token_b = create_and_login_user("MentorB")

    user_a_id = user_a.get("id") or user_a.get("user_id")
    user_b_id = user_b.get("id") or user_b.get("user_id")

    print(f"User A (Learner) ID: {user_a_id}, User B (Mentor) ID: {user_b_id}")

    # Make sure mentor B offers skill 1 (Python)
    make_req(f"{BASE_URL}/skills/1/offer", token=token_b, method="POST")

    # -------------------------------------------------------------
    # 1. BOOKING_REQUEST Event
    # -------------------------------------------------------------
    print("\n--- 1. Testing BOOKING_REQUEST Event ---")
    booking_payload = {
        "mentor_id": user_b_id,
        "skill_id": 1,
        "session_date": "2026-10-01T10:00:00Z",
        "credits_cost": 10
    }
    status, booking = make_req(f"{BASE_URL}/bookings", token=token_a, method="POST", body=booking_payload)
    assert status == 200, "Failed to create booking"
    booking_id = booking["id"]
    print(f"  [PASS] Created booking #{booking_id}")

    # Check Mentor B's notifications
    status, notifs_b = make_req(f"{BASE_URL}/notifications", token=token_b)
    assert status == 200
    req_notifs = [n for n in notifs_b if n.get("type") == "BOOKING_REQUEST"]
    print(f"  [PASS] Mentor B received BOOKING_REQUEST notification count: {len(req_notifs)}")
    assert len(req_notifs) >= 1, "Expected BOOKING_REQUEST notification for mentor"
    print(f"  [PASS] Title: {req_notifs[0]['title']} | Message: {req_notifs[0]['message']}")

    # -------------------------------------------------------------
    # 2. BOOKING_ACCEPTED Event
    # -------------------------------------------------------------
    print("\n--- 2. Testing BOOKING_ACCEPTED Event ---")
    status, _ = make_req(f"{BASE_URL}/bookings/{booking_id}/accept", token=token_b, method="POST")
    assert status == 200

    # Check Learner A's notifications
    status, notifs_a = make_req(f"{BASE_URL}/notifications", token=token_a)
    assert status == 200
    accept_notifs = [n for n in notifs_a if n.get("type") == "BOOKING_ACCEPTED"]
    print(f"  [PASS] Learner A received BOOKING_ACCEPTED notification count: {len(accept_notifs)}")
    assert len(accept_notifs) >= 1, "Expected BOOKING_ACCEPTED notification for learner"
    print(f"  [PASS] Title: {accept_notifs[0]['title']} | Message: {accept_notifs[0]['message']}")

    # -------------------------------------------------------------
    # 3. CREDIT_EARNED & CREDIT_SPENT Events on Completion
    # -------------------------------------------------------------
    print("\n--- 3. Testing CREDIT_EARNED & CREDIT_SPENT Events ---")
    status, _ = make_req(f"{BASE_URL}/bookings/{booking_id}/complete", token=token_a, method="POST")
    assert status == 200

    status, notifs_a = make_req(f"{BASE_URL}/notifications", token=token_a)
    spent_notifs = [n for n in notifs_a if n.get("type") == "CREDIT_SPENT"]
    print(f"  [PASS] Learner A CREDIT_SPENT count: {len(spent_notifs)}")
    assert len(spent_notifs) >= 1, "Expected CREDIT_SPENT notification"

    status, notifs_b = make_req(f"{BASE_URL}/notifications", token=token_b)
    earned_notifs = [n for n in notifs_b if n.get("type") == "CREDIT_EARNED"]
    print(f"  [PASS] Mentor B CREDIT_EARNED count: {len(earned_notifs)}")
    assert len(earned_notifs) >= 1, "Expected CREDIT_EARNED notification"

    # -------------------------------------------------------------
    # 4. QUIZ_COMPLETED Event
    # -------------------------------------------------------------
    print("\n--- 4. Testing QUIZ_COMPLETED Event ---")
    status, path_info = make_req(f"{BASE_URL}/learning/paths/skill/1", token=token_a)
    path_id = path_info["id"]
    status, lessons = make_req(f"{BASE_URL}/learning/paths/{path_id}/lessons", token=token_a)
    lesson_id = lessons[0]["id"]
    make_req(f"{BASE_URL}/learning/paths/{path_id}/start", token=token_a, method="POST")

    # Submit practice
    from backend.app.db.database import SessionLocal
    from backend.app.db.models import PracticeQuestion
    db = SessionLocal()
    try:
        db_qs = db.query(PracticeQuestion).filter(PracticeQuestion.lesson_id == lesson_id).all()
        correct_answers = [{"question_id": str(q.id), "answer": q.correct_answer} for q in db_qs]
    finally:
        db.close()

    status, _ = make_req(
        f"{BASE_URL}/learning/lessons/{lesson_id}/practice/submit",
        token=token_a,
        method="POST",
        body={"answers": correct_answers}
    )
    assert status == 200

    status, notifs_a = make_req(f"{BASE_URL}/notifications", token=token_a)
    quiz_notifs = [n for n in notifs_a if n.get("type") == "QUIZ_COMPLETED"]
    print(f"  [PASS] Learner A QUIZ_COMPLETED count: {len(quiz_notifs)}")
    assert len(quiz_notifs) >= 1, "Expected QUIZ_COMPLETED notification"
    print(f"  [PASS] Message: {quiz_notifs[0]['message']}")

    # -------------------------------------------------------------
    # 5. COURSE_COMPLETED & CERTIFICATE_ISSUED Events
    # -------------------------------------------------------------
    print("\n--- 5. Testing COURSE_COMPLETED & CERTIFICATE_ISSUED Events ---")
    for l in lessons:
        make_req(f"{BASE_URL}/learning/lessons/{l['id']}/complete", token=token_a, method="POST")

    status, notifs_a = make_req(f"{BASE_URL}/notifications", token=token_a)
    course_notifs = [n for n in notifs_a if n.get("type") == "COURSE_COMPLETED"]
    cert_notifs = [n for n in notifs_a if n.get("type") == "CERTIFICATE_ISSUED"]
    print(f"  [PASS] COURSE_COMPLETED count: {len(course_notifs)}")
    print(f"  [PASS] CERTIFICATE_ISSUED count: {len(cert_notifs)}")
    assert len(course_notifs) >= 1, "Expected COURSE_COMPLETED notification"
    assert len(cert_notifs) >= 1, "Expected CERTIFICATE_ISSUED notification"

    # -------------------------------------------------------------
    # 6. REVIEW_RECEIVED Event
    # -------------------------------------------------------------
    print("\n--- 6. Testing REVIEW_RECEIVED Event ---")
    review_payload = {
        "booking_id": booking_id,
        "reviewee_id": user_b_id,
        "rating": 5.0,
        "comment": "Outstanding Python session! Highly recommended."
    }
    status, _ = make_req(f"{BASE_URL}/reviews", token=token_a, method="POST", body=review_payload)
    assert status == 200

    status, notifs_b = make_req(f"{BASE_URL}/notifications", token=token_b)
    rev_notifs = [n for n in notifs_b if n.get("type") == "REVIEW_RECEIVED"]
    print(f"  [PASS] Mentor B REVIEW_RECEIVED count: {len(rev_notifs)}")
    assert len(rev_notifs) >= 1, "Expected REVIEW_RECEIVED notification"

    # -------------------------------------------------------------
    # 7. READ / MARK ALL READ / DELETE / USER ISOLATION
    # -------------------------------------------------------------
    print("\n--- 7. Testing Read State, Mark All Read, Deletion & User Isolation ---")
    # Verify User A notifications do not leak into User B
    for n in notifs_b:
        assert n["user_id"] == user_b_id, f"Cross-user notification leak detected: {n}"
    print("  [PASS] Strict user isolation verified (0 cross-user leaks)")

    # Test Mark Single Read
    first_notif_id = notifs_b[0]["id"]
    status, _ = make_req(f"{BASE_URL}/notifications/{first_notif_id}/read", token=token_b, method="POST")
    assert status == 200
    print(f"  [PASS] Marked notification #{first_notif_id} as read")

    # Test Mark All Read
    status, _ = make_req(f"{BASE_URL}/notifications/read-all", token=token_b, method="POST")
    assert status == 200
    status, notifs_b_after = make_req(f"{BASE_URL}/notifications", token=token_b)
    unread_remaining = [n for n in notifs_b_after if not n["is_read"]]
    print(f"  [PASS] Mark All Read executed. Unread remaining: {len(unread_remaining)}")
    assert len(unread_remaining) == 0, "Expected 0 unread notifications"

    # Test Single Delete
    status, _ = make_req(f"{BASE_URL}/notifications/{first_notif_id}", token=token_b, method="DELETE")
    assert status == 200
    status, notifs_b_final = make_req(f"{BASE_URL}/notifications", token=token_b)
    deleted_found = [n for n in notifs_b_final if n["id"] == first_notif_id]
    print(f"  [PASS] Deleted notification #{first_notif_id}. Remaining in list: {len(deleted_found)}")
    assert len(deleted_found) == 0, "Notification was not deleted"

    print("\n==================================================================")
    print(">>> ALL DYNAMIC NOTIFICATION PHASE 3 E2E TESTS PASSED! <<<")
    print("==================================================================")

if __name__ == "__main__":
    run_notifications_e2e_tests()
