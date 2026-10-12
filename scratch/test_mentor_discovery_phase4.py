import urllib.request
import urllib.parse
import json

BASE_URL = "http://127.0.0.1:8000/api/v1"

def http_post_form(url, data_dict):
    data_encoded = urllib.parse.urlencode(data_dict).encode('utf-8')
    req = urllib.request.Request(url, data=data_encoded, headers={'Content-Type': 'application/x-www-form-urlencoded'})
    with urllib.request.urlopen(req) as resp:
        return resp.status, json.loads(resp.read().decode('utf-8'))

def http_post_json(url, data_dict):
    data_encoded = json.dumps(data_dict).encode('utf-8')
    req = urllib.request.Request(url, data=data_encoded, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as resp:
        return resp.status, json.loads(resp.read().decode('utf-8'))

def http_get(url, headers=None):
    headers = headers or {}
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as resp:
        return resp.status, json.loads(resp.read().decode('utf-8'))

def test_mentor_discovery():
    print("==================================================")
    print("TESTING PHASE 4: SMART MENTOR DISCOVERY & MATCHING")
    print("==================================================")
    
    # 1. Login test user to get token
    try:
        status, token_data = http_post_form(f"{BASE_URL}/auth/token", {
            "username": "testuser@example.com",
            "password": "password123"
        })
    except Exception:
        status, token_data = http_post_json(f"{BASE_URL}/auth/login", {
            "email": "testuser@example.com",
            "password": "password123"
        })
        
    assert status == 200, f"Login failed with status {status}"
    token = token_data.get("access_token") or token_data.get("token")
    headers = {"Authorization": f"Bearer {token}"}
    print("[OK] Auth Token retrieved successfully")

    # 2. Test nearby users endpoint without search
    status, nearby = http_get(f"{BASE_URL}/users/nearby", headers=headers)
    assert status == 200, f"Nearby users failed: {status}"
    assert isinstance(nearby, list), "Nearby users response should be a list"
    print(f"[OK] GET /api/v1/users/nearby returned {len(nearby)} mentors")

    # 3. Test searching mentors by skill "Python"
    status, python_mentors = http_get(f"{BASE_URL}/users/nearby?skill=Python", headers=headers)
    assert status == 200, f"Skill search failed: {status}"
    print(f"[OK] GET /api/v1/users/nearby?skill=Python returned {len(python_mentors)} mentors")

    # 4. Test searching mentors by rating "min_rating=4.0"
    status, rated_mentors = http_get(f"{BASE_URL}/users/nearby?min_rating=4.0", headers=headers)
    assert status == 200, f"Rating filter failed: {status}"
    for m in rated_mentors:
        assert m.get("rating", 0) >= 4.0, f"Mentor rating {m.get('rating')} below 4.0"
    print(f"[OK] GET /api/v1/users/nearby?min_rating=4.0 verified {len(rated_mentors)} mentors (rating >= 4.0)")

    # 5. Test recommendations endpoint for AI match explanations
    status, rec_data = http_get(f"{BASE_URL}/recommendations/", headers=headers)
    assert status == 200, f"Recommendations failed: {status}"
    items = rec_data.get("data", rec_data) if isinstance(rec_data, dict) else rec_data
    assert len(items) > 0, "Recommendations should return at least one item"
    
    first_item = items[0]
    assert "mentor_id" in first_item, "Missing mentor_id in recommendation item"
    assert "explanation" in first_item, "Missing explanation in recommendation item"
    assert "reason" in first_item, "Missing reason in recommendation item"
    print(f"[OK] GET /api/v1/recommendations returned {len(items)} AI matches")
    exp = str(first_item.get('explanation')).encode('ascii', 'ignore').decode('ascii')
    rsn = str(first_item.get('reason')).encode('ascii', 'ignore').decode('ascii')
    print(f"  Sample Explanation: '{exp}'")
    print(f"  Sample Reason: '{rsn}'")

    print("\n==================================================")
    print("ALL PHASE 4 TESTS PASSED SUCCESSFULLY! (5/5)")
    print("==================================================")

if __name__ == "__main__":
    test_mentor_discovery()
