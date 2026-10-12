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

def create_and_login_user(name_prefix="CoachLearner"):
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

def run_ai_coach_e2e_tests():
    print("==================================================================")
    print(">>> RUNNING AI COACH DEEP INTEGRATION (PHASE 2) E2E TEST SUITE <<<")
    print("==================================================================")

    # -------------------------------------------------------------
    # Scenario 1: New Learner with Wanted Skill (Goal Gap)
    # -------------------------------------------------------------
    print("\n--- 1. Testing New Learner & Goal Gap Analysis ---")
    user, token = create_and_login_user("NewLearner")
    user_id = user.get("id") or user.get("user_id")
    print(f"Created Learner ID: {user_id}")

    # Add wanted skill (e.g. Python, skill_id 1)
    status, _ = make_req(f"{BASE_URL}/skills/1/want", token=token, method="POST")
    assert status == 200, "Failed to add wanted skill"

    # Get Coach Summary
    status, summary = make_req(f"{BASE_URL}/recommendations/coach/summary", token=token)
    assert status == 200, "Failed to fetch coach summary"
    print(f"  [PASS] Summary Hero Recommendation: {summary.get('hero_recommendation', {}).get('skill_name')}")
    print(f"  [PASS] Hero Reason: {summary.get('hero_recommendation', {}).get('reason')}")
    print(f"  [PASS] Daily Plan Items: {len(summary.get('daily_plan', []))}")
    assert len(summary.get('daily_plan', [])) >= 1, "Expected at least 1 daily plan item"

    # Verify Skill Gaps
    status, gaps = make_req(f"{BASE_URL}/recommendations/coach/skill-gaps", token=token)
    assert status == 200, "Failed to fetch skill gaps"
    print(f"  [PASS] Portfolio items: {len(gaps.get('skill_portfolio', []))}")
    goal_gaps = [p for p in gaps.get('skill_portfolio', []) if p.get('status') == 'Goal Gap']
    print(f"  [PASS] Detected Goal Gaps: {[g['skill_name'] for g in goal_gaps]}")
    assert len(goal_gaps) >= 1, "Expected at least 1 Goal Gap item"

    # -------------------------------------------------------------
    # Scenario 2: Adaptive Quiz Diagnostics (< 70% Weak Score)
    # -------------------------------------------------------------
    print("\n--- 2. Testing Adaptive Quiz Diagnostics (< 70% Score Triggers Revision) ---")
    user2, token2 = create_and_login_user("WeakScoreLearner")
    
    # Initialize learning path for skill 1
    status, path_info = make_req(f"{BASE_URL}/learning/paths/skill/1", token=token2)
    assert status == 200, "Failed to get/create learning path for skill 1"
    
    # Get lessons
    path_id = path_info["id"]
    status, lessons = make_req(f"{BASE_URL}/learning/paths/{path_id}/lessons", token=token2)
    assert status == 200 and len(lessons) > 0, "No lessons found for path"
    lesson_id = lessons[0]["id"]

    # Start learning
    make_req(f"{BASE_URL}/learning/paths/{path_id}/start", token=token2, method="POST")

    # Get practice questions
    status, questions = make_req(f"{BASE_URL}/learning/lessons/{lesson_id}/practice", token=token2)
    assert status == 200 and len(questions) > 0, "No practice questions found"

    # Submit wrong answers to get < 70%
    wrong_answers = [{"question_id": str(q["id"]), "answer": "WRONG_ANSWER_TEXT"} for q in questions]
    status, submit_res = make_req(
        f"{BASE_URL}/learning/lessons/{lesson_id}/practice/submit",
        token=token2,
        method="POST",
        body={"answers": wrong_answers}
    )
    assert status == 200, f"Practice submit failed: {status}"
    print(f"  [PASS] Submitted weak practice score: {submit_res.get('percentage')}%")

    # Fetch Coach Summary & verify Hero Rec is Revision
    status, summary2 = make_req(f"{BASE_URL}/recommendations/coach/summary", token=token2)
    assert status == 200
    hero2 = summary2.get("hero_recommendation", {})
    print(f"  [PASS] Weak score Hero Recommendation: {hero2.get('skill_name')} (Gap: {hero2.get('gap_level')})")
    print(f"  [PASS] Weak score Hero Reason: {hero2.get('reason')}")
    assert "revise" in hero2.get("reason", "").lower() or "practice" in hero2.get("reason", "").lower() or "score" in hero2.get("reason", "").lower() or "retake" in hero2.get("reason", "").lower(), "Expected reason to reference weak score / revision"

    # Fetch Diagnostics
    status, diag2 = make_req(f"{BASE_URL}/recommendations/coach/diagnostics", token=token2)
    assert status == 200
    print(f"  [PASS] Diagnostics Items: {len(diag2)}")
    weak_diags = [d for d in diag2 if d.get("status") == "needs_revision"]
    print(f"  [PASS] Needs Revision Diagnostics: {len(weak_diags)}")
    assert len(weak_diags) >= 1, "Expected diagnostic item with needs_revision status"
    print(f"  [PASS] Diagnostic Message: {weak_diags[0].get('message')}")
    print(f"  [PASS] Diagnostic Recommendation: {weak_diags[0].get('recommendation')}")

    # -------------------------------------------------------------
    # Scenario 3: Adaptive Quiz Diagnostics (>= 85% Mastery Score)
    # -------------------------------------------------------------
    print("\n--- 3. Testing High Quiz Mastery (>= 85% Score Triggers Advancement) ---")
    user3, token3 = create_and_login_user("MasterLearner")
    make_req(f"{BASE_URL}/learning/paths/{path_id}/start", token=token3, method="POST")

    # Lookup correct answers from database
    from backend.app.db.database import SessionLocal
    from backend.app.db.models import PracticeQuestion
    db = SessionLocal()
    try:
        db_qs = db.query(PracticeQuestion).filter(PracticeQuestion.lesson_id == lesson_id).all()
        correct_answers = [{"question_id": str(q.id), "answer": q.correct_answer} for q in db_qs]
    finally:
        db.close()

    status, high_res = make_req(
        f"{BASE_URL}/learning/lessons/{lesson_id}/practice/submit",
        token=token3,
        method="POST",
        body={"answers": correct_answers}
    )
    assert status == 200 and high_res.get("percentage") >= 85.0
    print(f"  [PASS] Submitted high mastery practice score: {high_res.get('percentage')}%")

    status, diag3 = make_req(f"{BASE_URL}/recommendations/coach/diagnostics", token=token3)
    assert status == 200
    mastered = [d for d in diag3 if d.get("status") == "mastered"]
    print(f"  [PASS] Mastered Diagnostics: {len(mastered)}")
    assert len(mastered) >= 1, "Expected diagnostic item with mastered status"
    print(f"  [PASS] Mastered Recommendation: {mastered[0].get('recommendation')}")

    # -------------------------------------------------------------
    # Scenario 4: Reciprocal Skill Exchange Intelligence (Zero Test Users)
    # -------------------------------------------------------------
    print("\n--- 4. Testing Reciprocal Skill Exchange Intelligence ---")
    user4, token4 = create_and_login_user("ExchangeLearner")
    # Learner offers skill 1 (Python) and wants skill 2 (Web Development)
    make_req(f"{BASE_URL}/skills/1/offer", token=token4, method="POST")
    make_req(f"{BASE_URL}/skills/2/want", token=token4, method="POST")

    status, exchanges = make_req(f"{BASE_URL}/recommendations/coach/exchanges", token=token4)
    assert status == 200
    suggestions = exchanges if isinstance(exchanges, list) else exchanges.get("exchange_suggestions", [])
    print(f"  [PASS] Exchange suggestions count: {len(suggestions)}")
    for s in suggestions:
        print(f"    - Partner: {s.get('partner_name')} | They teach: {s.get('they_teach_skill')} | You teach: {s.get('you_teach_skill')}")
        print(f"      Why: {s.get('reason')} | Confidence: {s.get('confidence_score')}%")
        assert not s.get("partner_name", "").startswith("Test_"), "Test account leaked into exchange suggestions!"

    # -------------------------------------------------------------
    # Scenario 5: Weekly Learning Activity & Study Velocity
    # -------------------------------------------------------------
    print("\n--- 5. Testing Weekly AI Insights & Study Minutes Calculation ---")
    status, weekly = make_req(f"{BASE_URL}/recommendations/coach/weekly-insights", token=token2)
    assert status == 200
    print(f"  [PASS] Week Range: {weekly.get('week_start')} to {weekly.get('week_end')}")
    print(f"  [PASS] Time Spent Minutes: {weekly.get('time_spent_minutes_week')}")
    print(f"  [PASS] Practice Attempts Week: {weekly.get('practice_attempts_week')}")
    print(f"  [PASS] Average Accuracy Week: {weekly.get('average_accuracy_week')}%")
    print(f"  [PASS] Consistency Rating: {weekly.get('consistency_rating')}")
    print(f"  [PASS] Highlights: {weekly.get('highlights')}")
    assert weekly.get('practice_attempts_week') >= 1, "Expected practice attempt to be counted in weekly metrics"

    # -------------------------------------------------------------
    # Scenario 6: Dedicated AI Learning Plan Endpoint
    # -------------------------------------------------------------
    print("\n--- 6. Testing Dedicated Daily Plan Endpoint ---")
    status, daily_plan_data = make_req(f"{BASE_URL}/recommendations/coach/daily-plan", token=token2)
    assert status == 200
    plan_items = daily_plan_data.get("daily_plan", [])
    print(f"  [PASS] Daily plan contains {len(plan_items)} structured tasks:")
    for item in plan_items:
        print(f"    [{item.get('priority')}] {item.get('title')} ({item.get('duration_minutes')} min) - {item.get('action_type')} (XP: +{item.get('reward_xp')})")
        print(f"      Reason: {item.get('reason')}")
        assert item.get('duration_minutes') > 0, "Daily plan item missing duration"
        assert item.get('action_type') in ['learn', 'learning', 'practice', 'exchange', 'review', 'passport', 'explore'], f"Invalid action type: {item.get('action_type')}"

    print("\n==================================================================")
    print(">>> ALL AI COACH PHASE 2 E2E TESTS PASSED SUCCESSFULLY! <<<")
    print("==================================================================")

if __name__ == "__main__":
    run_ai_coach_e2e_tests()
