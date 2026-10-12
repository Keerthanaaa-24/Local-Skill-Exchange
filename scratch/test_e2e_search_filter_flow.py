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

def run_tests():
    print("=================================================================")
    print("TESTING END-TO-END SEARCH, CATALOG & MULTI-CATEGORY OR FILTERING")
    print("=================================================================")

    # 1. Initial Catalog Load (All)
    status, res = http_request(f"{BASE_URL}/skills?page=1&limit=50")
    assert status == 200, f"Failed /skills: {res}"
    total = res.get("total", 0)
    items = res.get("data", [])
    print(f"[PASS] Initial Catalog (All): {total} total skills in DB, {len(items)} items returned in page 1")
    assert total >= 1500, f"Expected >= 1500 skills, got {total}"
    assert len(items) > 0, "Initial catalog items must not be empty"

    # 2. Search "python"
    status, res = http_request(f"{BASE_URL}/skills/search?q=python")
    assert status == 200
    items = res.get("data", [])
    print(f"[PASS] Search 'python': {len(items)} matching skills returned")
    assert len(items) >= 2, "Expected at least 2 python skills"

    # 3. Single Category: "Technology" / "Programming"
    status, res = http_request(f"{BASE_URL}/skills?category=Programming")
    assert status == 200
    items = res.get("data", [])
    print(f"[PASS] Category 'Programming': {len(items)} skills returned")
    assert len(items) > 0

    # 4. Single Category: "Design"
    status, res = http_request(f"{BASE_URL}/skills?category=Design")
    assert status == 200
    items = res.get("data", [])
    print(f"[PASS] Category 'Design': {len(items)} skills returned")
    assert len(items) > 0

    # 5. Single Category: "Music"
    status, res = http_request(f"{BASE_URL}/skills?category=Music")
    assert status == 200
    items = res.get("data", [])
    print(f"[PASS] Category 'Music': {len(items)} skills returned")
    assert len(items) > 0

    # 6. Multi-Category: "Technology + Design"
    status, res = http_request(f"{BASE_URL}/skills?categories=Technology,Design&page=1&limit=50")
    assert status == 200
    items = res.get("data", [])
    total_multi = res.get("total", 0)
    print(f"[PASS] Multi-Category 'Technology + Design': {total_multi} total skills, {len(items)} in page 1")
    assert len(items) > 0

    # 7. Exact Screenshot Scenario: "Languages + Music + Academic + Fitness + Cooking"
    status, res = http_request(f"{BASE_URL}/skills?categories=Languages,Music,Academic,Fitness,Cooking&page=1&limit=50")
    assert status == 200
    items = res.get("data", [])
    total_screen = res.get("total", 0)
    print(f"[PASS] Multi-Category 'Languages + Music + Academic + Fitness + Cooking' (Screenshot Scenario):")
    print(f"       -> Total matching skills in DB: {total_screen}")
    print(f"       -> Page 1 skills count: {len(items)}")
    assert total_screen > 0, "Screenshot scenario must NOT return zero!"
    assert len(items) > 0, "Screenshot scenario must return items!"

    # 8. Categories List
    status, categories = http_request(f"{BASE_URL}/skills/categories")
    assert status == 200
    print(f"[PASS] Categories endpoint: {len(categories)} distinct categories returned")
    assert len(categories) >= 20

    # 9. Custom Skill Creation & Search Retrieval
    unique_skill_name = f"QuantumRobotics_{int(time.time())}"
    # Register dynamic user
    email = f"custom_skill_user_{int(time.time())}@example.com"
    http_request(f"{BASE_URL}/auth/register", method="POST", data={"email": email, "name": "Custom Skill Tester", "password": "password123"})
    _, login_res = http_request(f"{BASE_URL}/auth/login", method="POST", form_data={"username": email, "password": "password123"})
    token = login_res["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    create_status, created = http_request(
        f"{BASE_URL}/skills/",
        method="POST",
        headers=headers,
        data={"name": unique_skill_name, "category": "Emerging Tech"}
    )
    assert create_status in [200, 201], f"Create custom skill failed: {created}"
    created_id = created.get("id")
    print(f"[PASS] Custom skill '{unique_skill_name}' created with ID {created_id}")

    # Search for created custom skill
    status, custom_search = http_request(f"{BASE_URL}/skills/search?q={unique_skill_name}")
    assert status == 200
    assert len(custom_search.get("data", [])) >= 1, "Custom skill must be searchable immediately"
    print(f"[PASS] Custom skill successfully retrieved via search")

    print("\nALL END-TO-END SEARCH, CATALOG & MULTI-CATEGORY OR TESTS PASSED!")

if __name__ == "__main__":
    run_tests()
