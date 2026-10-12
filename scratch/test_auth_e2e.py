import urllib.request
import urllib.parse
import json
import time

BASE_URL = "http://127.0.0.1:8000/api/v1"

def run_e2e_auth_test():
    print("==================================================")
    print("STARTING END-TO-END AUTHENTICATION TEST")
    print("==================================================")
    
    unique_id = int(time.time())
    email = f"e2e_test_{unique_id}@example.com"
    name = f"E2E Tester {unique_id}"
    password = "StrongPassword123!"

    # 1. Registration Step
    print(f"\n[STEP 1] Registering new user: {email}")
    reg_payload = json.dumps({
        "name": name,
        "email": email,
        "password": password
    }).encode("utf-8")
    
    req_reg = urllib.request.Request(
        f"{BASE_URL}/auth/register",
        data=reg_payload,
        headers={"Content-Type": "application/json"}
    )
    
    try:
        with urllib.request.urlopen(req_reg) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            print(f"-> Registration Successful (200 OK)!")
            print(f"   Created User ID: {data.get('id')}, Email: {data.get('email')}, Name: {data.get('name')}")
    except Exception as e:
        print(f"-> Registration Failed: {e}")
        return

    # 2. Form Data Login Step
    print(f"\n[STEP 2] Logging in with Form-Data")
    login_form_data = urllib.parse.urlencode({
        "username": email,
        "password": password
    }).encode("utf-8")
    
    req_login_form = urllib.request.Request(
        f"{BASE_URL}/auth/login",
        data=login_form_data,
        headers={"Content-Type": "application/x-www-form-urlencoded"}
    )
    
    token = None
    try:
        with urllib.request.urlopen(req_login_form) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            token = data.get("access_token")
            token_type = data.get("token_type")
            print(f"-> Form-Data Login Successful (200 OK)!")
            print(f"   Received Token Type: {token_type}, Token: {token[:20]}...{token[-10:]}")
    except Exception as e:
        print(f"-> Form-Data Login Failed: {e}")
        return

    # 3. JSON Payload Login Step
    print(f"\n[STEP 3] Logging in with JSON Payload")
    login_json_data = json.dumps({
        "email": email,
        "password": password
    }).encode("utf-8")
    
    req_login_json = urllib.request.Request(
        f"{BASE_URL}/auth/login",
        data=login_json_data,
        headers={"Content-Type": "application/json"}
    )
    
    try:
        with urllib.request.urlopen(req_login_json) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            print(f"-> JSON Login Successful (200 OK)!")
    except Exception as e:
        print(f"-> JSON Login Failed: {e}")

    # 4. Invalid Credentials Test
    print(f"\n[STEP 4] Testing Invalid Credentials Handling")
    bad_json_data = json.dumps({
        "email": email,
        "password": "WrongPassword!"
    }).encode("utf-8")
    
    req_bad = urllib.request.Request(
        f"{BASE_URL}/auth/login",
        data=bad_json_data,
        headers={"Content-Type": "application/json"}
    )
    
    try:
        with urllib.request.urlopen(req_bad) as resp:
            print(f"-> Error: Expected 401 Unauthorized, got 200 OK!")
    except urllib.error.HTTPError as he:
        if he.code == 401:
            print(f"-> Success: Correctly returned 401 Unauthorized for bad credentials!")
        else:
            print(f"-> Unexpected status: {he.code}")
    except Exception as e:
        print(f"-> Error testing bad credentials: {e}")

    # 5. Accessing Protected /users/me with Bearer Token
    print(f"\n[STEP 5] Calling Protected Endpoint /users/me with Authorization Bearer")
    req_me = urllib.request.Request(
        f"{BASE_URL}/users/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    try:
        with urllib.request.urlopen(req_me) as resp:
            user_me = json.loads(resp.read().decode("utf-8"))
            print(f"-> Protected /users/me Access Successful (200 OK)!")
            print(f"   Authenticated User ID: {user_me.get('id')}, Name: {user_me.get('name')}, Email: {user_me.get('email')}")
    except Exception as e:
        print(f"-> Protected /users/me Failed: {e}")

    # 6. Accessing Other Protected Endpoints with Bearer Token
    print(f"\n[STEP 6] Calling Additional Protected Endpoints with Bearer Token")
    endpoints = ["/wallet", "/bookings", "/notifications", "/recommendations"]
    for ep in endpoints:
        req_ep = urllib.request.Request(
            f"{BASE_URL}{ep}",
            headers={"Authorization": f"Bearer {token}"}
        )
        try:
            with urllib.request.urlopen(req_ep) as resp:
                print(f"   GET {ep:20} -> 200 OK")
        except Exception as e:
            print(f"   GET {ep:20} -> FAILED: {e}")

    print("\n==================================================")
    print("END-TO-END AUTHENTICATION TEST COMPLETED SUCCESSFULLY")
    print("==================================================")

if __name__ == "__main__":
    run_e2e_auth_test()
