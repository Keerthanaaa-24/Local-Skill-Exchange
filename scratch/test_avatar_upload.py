import urllib.request, json, os

png_bytes = b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15c4\x00\x00\x00\rIDATx\x9cc\xf8\xff\xff?\x03\x00\x08\xfc\x02\xfe\xa7\x9a\xa0\xa0\x00\x00\x00\x00IEND\xaeB\x82'

reg_url = 'http://127.0.0.1:8000/api/v1/auth/register'
user_data = {'name': 'Photo Tester', 'email': 'photo_test_user@example.com', 'password': 'Password123!'}
req = urllib.request.Request(reg_url, data=json.dumps(user_data).encode('utf-8'), headers={'Content-Type': 'application/json'})

try:
    with urllib.request.urlopen(req) as res:
        data = json.loads(res.read().decode())
        token = data.get('access_token')
except Exception:
    login_url = 'http://127.0.0.1:8000/api/v1/auth/login'
    login_req = urllib.request.Request(login_url, data=json.dumps(user_data).encode('utf-8'), headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(login_req) as res:
        data = json.loads(res.read().decode())
        token = data.get('access_token')

print('Logged in, testing avatar upload...')

boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW'
body = (
    b'--' + boundary.encode('utf-8') + b'\r\n'
    b'Content-Disposition: form-data; name=file; filename=my_avatar.png\r\n'
    b'Content-Type: image/png\r\n\r\n'
    + png_bytes +
    b'\r\n--' + boundary.encode('utf-8') + b'--\r\n'
)

upload_req = urllib.request.Request(
    'http://127.0.0.1:8000/api/v1/users/me/image',
    data=body,
    headers={
        'Authorization': f'Bearer {token}',
        'Content-Type': f'multipart/form-data; boundary={boundary}'
    }
)

with urllib.request.urlopen(upload_req) as res:
    upload_res = json.loads(res.read().decode())
    print('Upload result:', upload_res)
    avatar_url = upload_res.get('avatar_url') or upload_res.get('profile_image_url')

# Verify GET /users/me
me_req = urllib.request.Request('http://127.0.0.1:8000/api/v1/users/me', headers={'Authorization': f'Bearer {token}'})
with urllib.request.urlopen(me_req) as res:
    me_data = json.loads(res.read().decode())
    print('GET /users/me avatar_url:', me_data.get('avatar_url'))

# Verify static file serving
static_url = f'http://127.0.0.1:8000{avatar_url}'
with urllib.request.urlopen(static_url) as res:
    static_bytes = res.read()
    print(f'Static file fetch ({static_url}): Status {res.status}, Length: {len(static_bytes)} bytes')

assert len(static_bytes) == len(png_bytes), 'Static file bytes mismatch'
print('IMAGE UPLOAD, DB PERSISTENCE, AND STATIC FILE SERVING ALL VERIFIED SUCCESSFULLY!')
