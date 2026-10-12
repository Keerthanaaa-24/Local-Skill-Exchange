import urllib.request
import urllib.parse
import json
import sys
import time
import random

BASE_URL = "http://127.0.0.1:8000/api/v1"

def make_req(url, token=None):
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as res:
        return res.status, json.loads(res.read().decode())

def get_auth_token():
    test_email = f"category_tester_{int(time.time())}_{random.randint(100,999)}@example.com"
    data = json.dumps({"name": "Category Tester", "email": test_email, "password": "password123"}).encode("utf-8")
    req = urllib.request.Request(f"{BASE_URL}/auth/register", data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as res:
        pass
    
    login_data = urllib.parse.urlencode({"username": test_email, "password": "password123"}).encode("utf-8")
    req2 = urllib.request.Request(f"{BASE_URL}/auth/login", data=login_data, headers={"Content-Type": "application/x-www-form-urlencoded"})
    with urllib.request.urlopen(req2) as res2:
        body = json.loads(res2.read().decode())
        return body["access_token"]

def run_tests():
    print("==================================================================")
    print(">>> RUNNING CATEGORY-WISE SKILL FILTERING E2E TEST SUITE <<<")
    print("==================================================================")

    token = get_auth_token()
    print("Obtained valid auth token for tests.")

    # 1. Dynamic Category Counts Endpoint
    print("\n--- 1. Testing GET /api/v1/skills/categories ---")
    status, categories = make_req(f"{BASE_URL}/skills/categories", token=token)
    assert status == 200
    counts_map = {item["category"]: item["count"] for item in categories}
    print(f"Categories returned ({len(categories)}): {counts_map}")
    
    assert "All" in counts_map and counts_map["All"] > 1000, "All category count must exceed 1000"
    for cat in [
        "Academics",
        "Languages",
        "Programming & Technology",
        "Professional Skills",
        "Creative Skills",
        "Practical / Life Skills"
    ]:
        assert cat in counts_map, f"Missing category: {cat}"
        count = counts_map[cat]
        print(f"  [PASS] {cat}: {count} skills (>= 10 requirement satisfied)")
        assert count >= 10, f"{cat} has fewer than 10 skills: {count}"

    # 2. Category: ALL
    print("\n--- 2. Testing Category: ALL ---")
    status, res_all = make_req(f"{BASE_URL}/skills/?limit=30", token=token)
    assert status == 200
    skills_all = res_all.get("data", [])
    assert len(skills_all) > 0
    print(f"  [PASS] All skills returned: {len(skills_all)} items. Total in DB: {res_all.get('total')}")

    # 3. Category: ACADEMICS
    print("\n--- 3. Testing Category: Academics ---")
    status, res_acad = make_req(f"{BASE_URL}/skills/?category=Academics&limit=50", token=token)
    assert status == 200
    skills_acad = res_acad.get("data", [])
    assert len(skills_acad) >= 10
    for s in skills_acad:
        assert s["category_name"] == "Academics", f"Wrong category: {s['category_name']} for skill {s['title']}"
        assert not s["title"].startswith("Skill_Updated_")
        assert not s["title"].startswith("SkillDirectTest")
    acad_titles = [s["title"] for s in skills_acad]
    print(f"  [PASS] Academics: {len(skills_acad)} items returned. Sample: {acad_titles[:4]}")

    # Check Mathematics in Academics
    status, res_math = make_req(f"{BASE_URL}/skills/?category=Academics&q=Math", token=token)
    assert status == 200
    math_skills = res_math.get("data", [])
    assert len(math_skills) >= 1, "Mathematics skill must be present under Academics"
    print(f"  [PASS] Mathematics found under Academics: {[s['title'] for s in math_skills]}")

    # 4. Category: LANGUAGES
    print("\n--- 4. Testing Category: Languages ---")
    status, res_lang = make_req(f"{BASE_URL}/skills/?category=Languages&limit=50", token=token)
    assert status == 200
    skills_lang = res_lang.get("data", [])
    assert len(skills_lang) >= 10
    for s in skills_lang:
        assert s["category_name"] == "Languages", f"Wrong category: {s['category_name']} for skill {s['title']}"
        assert not s["title"].startswith("Skill_Updated_")
    lang_titles = [s["title"] for s in skills_lang]
    print(f"  [PASS] Languages: {len(skills_lang)} items returned. Sample: {lang_titles[:4]}")

    # Check Hindi in Languages
    status, res_hindi = make_req(f"{BASE_URL}/skills/?category=Languages&q=Hindi", token=token)
    assert status == 200
    hindi_skills = res_hindi.get("data", [])
    assert len(hindi_skills) >= 1, "Hindi skill must be present under Languages"
    print(f"  [PASS] Hindi found under Languages: {[s['title'] for s in hindi_skills]}")

    # 5. Category: PROGRAMMING & TECHNOLOGY
    print("\n--- 5. Testing Category: Programming & Technology ---")
    status, res_prog = make_req(f"{BASE_URL}/skills/?category=Programming%20%26%20Technology&limit=50", token=token)
    assert status == 200
    skills_prog = res_prog.get("data", [])
    assert len(skills_prog) >= 10
    for s in skills_prog:
        assert s["category_name"] == "Programming & Technology", f"Wrong category: {s['category_name']} for skill {s['title']}"
        assert not s["title"].startswith("Skill_Updated_")
    prog_titles = [s["title"] for s in skills_prog]
    print(f"  [PASS] Programming & Technology: {len(skills_prog)} items returned. Sample: {prog_titles[:4]}")

    # Check Python in Programming & Technology
    status, res_py = make_req(f"{BASE_URL}/skills/?category=Programming%20%26%20Technology&q=Python", token=token)
    assert status == 200
    py_skills = res_py.get("data", [])
    assert len(py_skills) >= 1, "Python skill must be present under Programming & Technology"
    print(f"  [PASS] Python found under Programming & Technology: {[s['title'] for s in py_skills]}")

    # 6. Category: PROFESSIONAL SKILLS
    print("\n--- 6. Testing Category: Professional Skills ---")
    status, res_prof = make_req(f"{BASE_URL}/skills/?category=Professional%20Skills&limit=50", token=token)
    assert status == 200
    skills_prof = res_prof.get("data", [])
    assert len(skills_prof) >= 10
    for s in skills_prof:
        assert s["category_name"] == "Professional Skills", f"Wrong category: {s['category_name']} for skill {s['title']}"
        assert not s["title"].startswith("Skill_Updated_")
    prof_titles = [s["title"] for s in skills_prof]
    print(f"  [PASS] Professional Skills: {len(skills_prof)} items returned. Sample: {prof_titles[:4]}")

    # Check Communication in Professional Skills
    status, res_comm = make_req(f"{BASE_URL}/skills/?category=Professional%20Skills&q=Communication", token=token)
    assert status == 200
    comm_skills = res_comm.get("data", [])
    assert len(comm_skills) >= 1, "Communication skill must be present under Professional Skills"
    print(f"  [PASS] Communication found under Professional Skills: {[s['title'] for s in comm_skills]}")

    # 7. Category: CREATIVE SKILLS
    print("\n--- 7. Testing Category: Creative Skills ---")
    status, res_creat = make_req(f"{BASE_URL}/skills/?category=Creative%20Skills&limit=50", token=token)
    assert status == 200
    skills_creat = res_creat.get("data", [])
    assert len(skills_creat) >= 10
    for s in skills_creat:
        assert s["category_name"] == "Creative Skills", f"Wrong category: {s['category_name']} for skill {s['title']}"
        assert not s["title"].startswith("Skill_Updated_")
    creat_titles = [s["title"] for s in skills_creat]
    print(f"  [PASS] Creative Skills: {len(skills_creat)} items returned. Sample: {creat_titles[:4]}")

    # Check Photography in Creative Skills
    status, res_photo = make_req(f"{BASE_URL}/skills/?category=Creative%20Skills&q=Photo", token=token)
    assert status == 200
    photo_skills = res_photo.get("data", [])
    assert len(photo_skills) >= 1, "Photography skill must be present under Creative Skills"
    print(f"  [PASS] Photography found under Creative Skills: {[s['title'] for s in photo_skills]}")

    # 8. Category: PRACTICAL / LIFE SKILLS
    print("\n--- 8. Testing Category: Practical / Life Skills ---")
    status, res_prac = make_req(f"{BASE_URL}/skills/?category=Practical%20%2F%20Life%20Skills&limit=50", token=token)
    assert status == 200
    skills_prac = res_prac.get("data", [])
    assert len(skills_prac) >= 10
    for s in skills_prac:
        assert s["category_name"] == "Practical / Life Skills", f"Wrong category: {s['category_name']} for skill {s['title']}"
        assert not s["title"].startswith("Skill_Updated_")
    prac_titles = [s["title"] for s in skills_prac]
    print(f"  [PASS] Practical / Life Skills: {len(skills_prac)} items returned. Sample: {prac_titles[:4]}")

    # Check Culinary / Cooking in Practical / Life Skills
    status, res_cook = make_req(f"{BASE_URL}/skills/?category=Practical%20%2F%20Life%20Skills&q=Culinary", token=token)
    assert status == 200
    cook_skills = res_cook.get("data", [])
    assert len(cook_skills) >= 1, "Culinary skill must be present under Practical / Life Skills"
    print(f"  [PASS] Culinary found under Practical / Life Skills: {[s['title'] for s in cook_skills]}")

    # 9. Pagination Verification Across Entire Database
    print("\n--- 9. Testing Pagination Across Whole Database ---")
    status, p1 = make_req(f"{BASE_URL}/skills/?category=Programming%20%26%20Technology&page=1&limit=15", token=token)
    status, p2 = make_req(f"{BASE_URL}/skills/?category=Programming%20%26%20Technology&page=2&limit=15", token=token)
    assert status == 200
    p1_ids = {s["id"] for s in p1["data"]}
    p2_ids = {s["id"] for s in p2["data"]}
    assert len(p1_ids.intersection(p2_ids)) == 0, "Page 1 and Page 2 must not have overlapping skills"
    print(f"  [PASS] Pagination verified: Page 1 ({len(p1_ids)} items) and Page 2 ({len(p2_ids)} items) are distinct.")

    # 10. Connection to Learning Platform (Courses, Lessons, Materials, Practice, Quiz)
    print("\n--- 10. Testing Learning Platform Connection for Flagship Skills ---")
    for skill_name, cat_expected in [
        ("Python Programming", "Programming & Technology"),
        ("Hindi Language Speaking & Devanagari Script", "Languages"),
        ("Discrete Mathematics (Set Theory, Combinatorics, Graph Theory)", "Academics"),
        ("Action Sports Photography & High Burst Shutter", "Creative Skills"),
        ("Public Speaking & Executive Presence", "Professional Skills"),
        ("3D Modeling for Fabrication (Autodesk Fusion 360)", "Practical / Life Skills")
    ]:
        status, s_res = make_req(f"{BASE_URL}/skills/search?q={urllib.parse.quote(skill_name)}", token=token)
        s_list = s_res.get("data", [])
        assert len(s_list) >= 1, f"Could not find skill: {skill_name}"
        target_skill = s_list[0]
        assert target_skill["category_name"] == cat_expected, f"Skill {skill_name} expected category {cat_expected}, got {target_skill['category_name']}"

        # Fetch learning path for this skill
        status, path_res = make_req(f"{BASE_URL}/learning/paths/skill/{target_skill['id']}", token=token)
        assert status == 200, f"Learning path failed for skill {skill_name}"
        path_id = path_res["id"]
        
        # Fetch lessons
        status, lessons = make_req(f"{BASE_URL}/learning/paths/{path_id}/lessons", token=token)
        assert status == 200 and len(lessons) >= 1, f"Lessons missing for path {path_id}"
        print(f"  [PASS] {skill_name} -> Category: {cat_expected} -> Path #{path_id} -> {len(lessons)} lessons verified.")

    print("\n==================================================================")
    print(">>> ALL CATEGORY FILTERING & INTEGRATION TESTS PASSED CLEANLY! <<<")
    print("==================================================================")

if __name__ == "__main__":
    run_tests()
