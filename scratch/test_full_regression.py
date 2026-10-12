import urllib.request
import urllib.parse
import urllib.error
import json
import time
import random
import sys

BASE_URL = "http://127.0.0.1:8000/api/v1"

passed = 0
failed = 0

def test(name, condition, extra=""):
    global passed, failed
    if condition:
        passed += 1
        print(f"  [PASS] {name} {extra}")
    else:
        failed += 1
        print(f"  [FAIL] {name} {extra}")

def req(method, path, data=None, token=None, content_type="application/json"):
    url = f"{BASE_URL}{path}"
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = None
    if data is not None:
        if content_type == "application/json":
            headers["Content-Type"] = "application/json"
            body = json.dumps(data).encode("utf-8")
        elif content_type == "application/x-www-form-urlencoded":
            headers["Content-Type"] = "application/x-www-form-urlencoded"
            body = urllib.parse.urlencode(data).encode("utf-8")
    request = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            res_body = response.read().decode("utf-8")
            try:
                parsed = json.loads(res_body)
            except Exception:
                parsed = res_body
            return response.status, parsed
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        try:
            parsed = json.loads(err_body)
        except Exception:
            parsed = err_body
        return e.code, parsed

def run_test():
    print("===============================================================")
    print("STARTING COMPLETE END-TO-END SYSTEM AUDIT (ALL 14 MODULES)")
    print("===============================================================")

    # 1. AUTHENTICATION & USER PROFILE
    print("\n--- 1. AUTHENTICATION & USER PROFILE ---")
    test_email = f"audit_user_{int(time.time())}_{random.randint(100,999)}@example.com"
    status, reg_res = req("POST", "/auth/register", {"name": "Audit Tester", "email": test_email, "password": "password123"})
    test("POST /auth/register", status == 200, f"User ID: {reg_res.get('id')}")

    status, login_res = req("POST", "/auth/login", {"username": test_email, "password": "password123"}, content_type="application/x-www-form-urlencoded")
    test("POST /auth/login (Form)", status == 200)
    token = login_res.get("access_token")

    status, login_json = req("POST", "/auth/login", {"email": test_email, "password": "password123"})
    test("POST /auth/login (JSON)", status == 200)

    status, bad_login = req("POST", "/auth/login", {"email": test_email, "password": "wrongpass"})
    test("POST /auth/login (Bad Pass -> 401)", status == 401)

    status, me_res = req("GET", "/users/me", token=token)
    test("GET /users/me", status == 200 and me_res.get("email") == test_email)
    user_id = me_res.get("id")

    status, update_res = req("PUT", "/users/me", {"name": "Audit Tester Updated", "title": "Senior Auditor", "lat": 12.9716, "lng": 77.5946}, token=token)
    test("PUT /users/me (Edit Profile)", status == 200 and update_res.get("name") == "Audit Tester Updated")

    status, pass_res = req("POST", "/users/me/password", {"current_password": "password123", "new_password": "newpassword456"}, token=token)
    test("POST /users/me/password (Change Password)", status == 200)

    status, new_login = req("POST", "/auth/login", {"email": test_email, "password": "newpassword456"})
    test("POST /auth/login (New Password)", status == 200)
    token = new_login.get("access_token")

    status, img_res = req("POST", "/users/me/image", {}, token=token)
    test("POST /users/me/image", status == 200)

    status, u_res = req("GET", f"/users/{user_id}", token=token)
    test("GET /users/{id}", status == 200 and u_res.get("id") == user_id)

    # 2. NEARBY USERS
    print("\n--- 2. NEARBY USERS ---")
    status, unauth_nearby = req("GET", "/users/nearby")
    test("GET /users/nearby (Unauthenticated)", status == 200, f"Count: {len(unauth_nearby)}")
    status, auth_nearby = req("GET", "/users/nearby", token=token)
    test("GET /users/nearby (Authenticated)", status == 200, f"Count: {len(auth_nearby)}")

    # 3. SKILLS
    print("\n--- 3. SKILLS ---")
    status, skills_list = req("GET", "/skills")
    test("GET /skills", status == 200)
    status, search_res = req("GET", "/skills/search?q=Python")
    test("GET /skills/search", status == 200)
    status, cat_res = req("GET", "/skills/category/Technology")
    test("GET /skills/category/Tech", status == 200)

    status, create_skill_res = req("POST", "/skills", {"name": f"Skill_{random.randint(1000,9999)}", "category": "Programming"}, token=token)
    test("POST /skills (Create)", status == 200)
    new_skill_id = create_skill_res.get("id")

    status, skill_get = req("GET", f"/skills/{new_skill_id}")
    test("GET /skills/{id}", status == 200)

    status, offer_res = req("POST", f"/skills/{new_skill_id}/offer", token=token)
    test("POST /skills/{id}/offer", status == 200)

    status, want_res = req("POST", f"/skills/{new_skill_id}/request", token=token)
    test("POST /skills/{id}/request", status == 200)

    status, patch_res = req("PATCH", f"/skills/{new_skill_id}", {"name": f"Skill_Updated_{random.randint(1000,9999)}"}, token=token)
    test("PATCH /skills/{id}", status == 200)

    status, del_res = req("DELETE", f"/skills/{new_skill_id}", token=token)
    test("DELETE /skills/{id}", status == 200)

    # 4. RECOMMENDATIONS
    print("\n--- 4. SMART MATCHING & RECOMMENDATIONS ---")
    status, rec_res = req("GET", "/recommendations", token=token)
    test("GET /recommendations", status == 200)

    # 5. BOOKINGS
    print("\n--- 5. BOOKINGS ---")
    mentor_id = 1
    status, book_create = req("POST", "/bookings", {"mentor_id": mentor_id, "skill_id": 1, "date": "2026-10-01T10:00:00", "location": "Online", "credits_cost": 10}, token=token)
    test("POST /bookings (Create)", status == 200, f"Booking ID: {book_create.get('id')}")
    booking_id = book_create.get("id")

    status, all_bookings = req("GET", "/bookings", token=token)
    test("GET /bookings (All)", status == 200)

    status, up_bookings = req("GET", "/bookings/upcoming", token=token)
    test("GET /bookings/upcoming", status == 200)

    status, b_detail = req("GET", f"/bookings/{booking_id}", token=token)
    test("GET /bookings/{id}", status == 200)

    status, cancel_res = req("POST", f"/bookings/{booking_id}/cancel", token=token)
    test("POST /bookings/{id}/cancel", status == 200)

    # Create another booking and complete it
    status, book_comp = req("POST", "/bookings", {"mentor_id": mentor_id, "skill_id": 1, "date": "2026-10-02T10:00:00", "location": "Online", "credits_cost": 10}, token=token)
    comp_booking_id = book_comp.get("id")
    status, comp_res = req("POST", f"/bookings/{comp_booking_id}/complete", token=token)
    test("POST /bookings/{id}/complete", status == 200)

    status, past_bookings = req("GET", "/bookings/completed", token=token)
    test("GET /bookings/completed", status == 200)

    # 6. WALLET
    print("\n--- 6. WALLET & CREDITS ---")
    status, wallet_res = req("GET", "/wallet", token=token)
    test("GET /wallet", status == 200, f"Balance: {wallet_res.get('balance')}")

    status, tx_res = req("GET", "/wallet/transactions", token=token)
    test("GET /wallet/transactions", status == 200, f"Count: {len(tx_res)}")

    if tx_res:
        tx_id = tx_res[0].get("transaction_id")
        status, tx_detail = req("GET", f"/wallet/transactions/{tx_id}", token=token)
        test("GET /wallet/transactions/{id}", status == 200)

    # 7. REVIEWS
    print("\n--- 7. REVIEWS ---")
    status, rev_create = req("POST", "/reviews", {"booking_id": comp_booking_id, "reviewed_user_id": mentor_id, "rating": 5.0, "comment": "Excellent mentor!"}, token=token)
    test("POST /reviews (Create)", status == 200)
    rev_id = rev_create.get("id") or rev_create.get("review_id")

    status, u_reviews = req("GET", f"/reviews/user/{mentor_id}", token=token)
    test("GET /reviews/user/{id}", status == 200)

    status, stats_res = req("GET", f"/reviews/user/{mentor_id}/statistics", token=token)
    test("GET /reviews/user/{id}/statistics", status == 200)

    if rev_id:
        status, r_detail = req("GET", f"/reviews/{rev_id}", token=token)
        test("GET /reviews/{id}", status == 200)
        status, r_update = req("PUT", f"/reviews/{rev_id}", {"rating": 4.5, "comment": "Updated review comment"}, token=token)
        test("PUT /reviews/{id}", status == 200)
        status, r_del = req("DELETE", f"/reviews/{rev_id}", token=token)
        test("DELETE /reviews/{id}", status == 200)

    # 8. NOTIFICATIONS
    print("\n--- 8. NOTIFICATIONS ---")
    status, notifs = req("GET", "/notifications", token=token)
    test("GET /notifications", status == 200, f"Count: {len(notifs)}")

    if notifs:
        nid = notifs[0].get("id")
        status, n_read = req("POST", f"/notifications/{nid}/read", token=token)
        test("POST /notifications/{id}/read", status == 200)

    status, n_readall = req("POST", "/notifications/read-all", token=token)
    test("POST /notifications/read-all", status == 200)

    # 9. LEARNING & PRACTICE
    print("\n--- 9. LEARNING & PRACTICE ---")
    status, paths = req("GET", "/learning/paths", token=token)
    test("GET /learning/paths", status == 200, f"Paths: {len(paths)}")

    if paths:
        pid = paths[0].get("id")
        status, p_detail = req("GET", f"/learning/paths/{pid}", token=token)
        test("GET /learning/paths/{id}", status == 200)

        status, lessons = req("GET", f"/learning/paths/{pid}/lessons", token=token)
        test("GET /learning/paths/{id}/lessons", status == 200, f"Lessons: {len(lessons)}")

        status, start_res = req("POST", f"/learning/paths/{pid}/start", token=token)
        test("POST /learning/paths/{id}/start", status == 200)

        status, user_prog = req("GET", "/learning/progress", token=token)
        test("GET /learning/progress", status == 200)

        status, prog_id = req("GET", f"/learning/progress/{pid}", token=token)
        test("GET /learning/progress/{id}", status == 200)

        if lessons:
            lid = lessons[0].get("id")
            status, l_comp = req("POST", f"/learning/lessons/{lid}/complete", token=token)
            test("POST /learning/lessons/{id}/complete", status == 200)

            status, practice_qs = req("GET", f"/learning/lessons/{lid}/practice", token=token)
            test("GET /learning/lessons/{id}/practice", status == 200, f"Questions: {len(practice_qs)}")

            if practice_qs:
                answers = [{"question_id": str(q.get("id")), "answer": (q.get("options") or ["Option A"])[0]} for q in practice_qs]
                status, sub_res = req("POST", f"/learning/lessons/{lid}/practice/submit", {"answers": answers}, token=token)
                test("POST /learning/lessons/{id}/practice/submit", status == 200 and isinstance(sub_res, dict) and "passed" in sub_res, f"Passed: {sub_res.get('passed')}")

                status, hist_res = req("GET", f"/learning/lessons/{lid}/practice/history", token=token)
                test("GET /learning/lessons/{id}/practice/history", status == 200)

    # 10. CERTIFICATES
    print("\n--- 10. CERTIFICATES ---")
    status, certs_list = req("GET", "/certificates", token=token)
    test("GET /certificates", status == 200, f"Certs: {len(certs_list)}")

    if certs_list:
        cid = certs_list[0].get("id")
        code = certs_list[0].get("verification_code")
        status, c_detail = req("GET", f"/certificates/{cid}", token=token)
        test("GET /certificates/{id}", status == 200)
        if code:
            status, v_res = req("GET", f"/certificates/verify/{code}")
            test("GET /certificates/verify/{code} (Public)", status == 200)

    # 11. SKILL PASSPORT
    print("\n--- 11. SKILL PASSPORT ---")
    status, my_pass = req("GET", "/passport/me", token=token)
    user_name = my_pass.get("user", {}).get("name") if isinstance(my_pass, dict) else "N/A"
    test("GET /passport/me", status == 200, f"Passport User: {user_name}")

    status, pub_pass = req("GET", f"/passport/user/{user_id}", token=token)
    test("GET /passport/user/{id} (Public)", status == 200)

    # 12. COMMUNITY & SAFETY
    print("\n--- 12. COMMUNITY & SAFETY ---")
    status, comm_act = req("GET", "/community/activity")
    test("GET /community/activity", status == 200, f"Activities: {len(comm_act)}")

    status, u_act = req("GET", f"/community/activity/user/{user_id}")
    test("GET /community/activity/user/{id}", status == 200)

    status, comm_prof = req("GET", f"/community/profile/{user_id}", token=token)
    test("GET /community/profile/{id}", status == 200)

    status, comm_disc = req("GET", "/community/discovery")
    test("GET /community/discovery", status == 200)

    status, rep_res = req("POST", "/safety/report", {"reported_user_id": mentor_id, "reason": "spam", "description": "Test report"}, token=token)
    test("POST /safety/report", status == 200)

    status, blk_res = req("POST", f"/safety/block/{mentor_id}", token=token)
    test("POST /safety/block/{id}", status == 200)

    status, blks_list = req("GET", "/safety/blocks", token=token)
    test("GET /safety/blocks", status == 200 and mentor_id in blks_list)

    status, unblk_res = req("DELETE", f"/safety/block/{mentor_id}", token=token)
    test("DELETE /safety/block/{id}", status == 200)

    # 13. GAMIFICATION
    print("\n--- 13. GAMIFICATION ---")
    status, dash_res = req("GET", "/gamification/dashboard", token=token)
    xp_val = dash_res.get("total_xp") if isinstance(dash_res, dict) else 0
    test("GET /gamification/dashboard", status == 200, f"XP: {xp_val}")

    status, ach_res = req("GET", "/gamification/achievements", token=token)
    test("GET /gamification/achievements", status == 200)

    status, lb_res = req("GET", "/gamification/leaderboard", token=token)
    test("GET /gamification/leaderboard", status == 200)

    status, time_res = req("GET", f"/gamification/timeline/{user_id}", token=token)
    test("GET /gamification/timeline/{id}", status == 200)

    # 14. CHAT REST ENDPOINTS
    print("\n--- 14. CHAT REST ENDPOINTS ---")
    status, chats_list = req("GET", "/chats", token=token)
    test("GET /chats", status == 200)

    status, chat_msgs = req("GET", f"/chats/{mentor_id}/messages", token=token)
    test("GET /chats/{id}/messages", status == 200)

    print("\n===============================================================")
    print(f"SYSTEM AUDIT COMPLETE: {passed} PASSED, {failed} FAILED")
    print("===============================================================")
    if failed > 0:
        sys.exit(1)

if __name__ == "__main__":
    run_test()

