# API Documentation — Local Skill Exchange

Base URL: `http://127.0.0.1:8000/api/v1`  
OpenAPI Interactive Docs: `http://127.0.0.1:8000/docs`  
ReDoc Documentation: `http://127.0.0.1:8000/redoc`

---

## 1. Authentication (`/auth`)

| Method | Endpoint | Auth | Purpose | Request Body | Status Codes |
|---|---|---|---|---|---|
| `POST` | `/auth/register` | None | Register a new user | `{ "name", "email", "password" }` | `200 OK`, `400 Bad Request` |
| `POST` | `/auth/login` | None | OAuth2 password login | Form: `username`, `password` | `200 OK`, `401 Unauthorized` |

---

## 2. Users (`/users`)

| Method | Endpoint | Auth | Purpose | Response / Details | Status Codes |
|---|---|---|---|---|---|
| `GET` | `/users/me` | Bearer | Current user profile | Returns full authenticated `User` | `200 OK`, `401 Unauthorized` |
| `PUT` | `/users/me` | Bearer | Update user profile | Updates title, bio, location, lat/lng | `200 OK`, `401 Unauthorized` |
| `GET` | `/users/nearby` | Bearer | Nearby community mentors | Returns user list sorted by distance | `200 OK`, `401 Unauthorized` |
| `GET` | `/users/{user_id}` | None/Bearer | Public user profile | Safe public profile fields | `200 OK`, `404 Not Found` |

---

## 3. Skills (`/skills`)

| Method | Endpoint | Auth | Purpose | Response / Details | Status Codes |
|---|---|---|---|---|---|
| `GET` | `/skills/` | None | List skill catalog | List of available skills & categories | `200 OK` |
| `POST` | `/skills/offer/{id}` | Bearer | Add skill to offered list | Links skill to user's offered list | `200 OK`, `404 Not Found` |
| `DELETE` | `/skills/offer/{id}` | Bearer | Remove offered skill | Unlinks offered skill | `200 OK`, `404 Not Found` |
| `POST` | `/skills/want/{id}` | Bearer | Add skill to wanted list | Links skill to user's wanted list | `200 OK`, `404 Not Found` |
| `DELETE` | `/skills/want/{id}` | Bearer | Remove wanted skill | Unlinks wanted skill | `200 OK`, `404 Not Found` |

---

## 4. Learning (`/learning`)

| Method | Endpoint | Auth | Purpose | Response / Details | Status Codes |
|---|---|---|---|---|---|
| `GET` | `/learning/paths` | Bearer | List learning paths | Learning paths with lesson counts | `200 OK` |
| `GET` | `/learning/paths/{id}` | Bearer | Get learning path detail | Path details & lesson tree | `200 OK`, `404 Not Found` |
| `GET` | `/learning/paths/{id}/lessons` | Bearer | List lessons in path | Lessons sorted by order | `200 OK`, `404 Not Found` |
| `POST` | `/learning/lessons/{id}/complete` | Bearer | Complete a lesson | Updates user progress & awards +20 XP | `200 OK`, `404 Not Found` |
| `GET` | `/learning/progress` | Bearer | Get user progress records | Progress across enrolled paths | `200 OK` |

---

## 5. Practice (`/learning/lessons/.../practice`)

| Method | Endpoint | Auth | Purpose | Security Notes | Status Codes |
|---|---|---|---|---|---|
| `GET` | `.../{id}/practice` | Bearer | Fetch practice questions | `correct_answer` is stripped | `200 OK`, `404 Not Found` |
| `POST` | `.../{id}/practice/submit` | Bearer | Submit answers for scoring | Server-side evaluation & scoring | `200 OK`, `400 Bad Request` |
| `GET` | `.../{id}/practice/history` | Bearer | Get quiz attempt history | Past attempts with score & pass/fail | `200 OK` |

---

## 6. Certificates (`/certificates`)

| Method | Endpoint | Auth | Purpose | Status Codes |
|---|---|---|---|---|
| `GET` | `/certificates/` | Bearer | List user certificates | `200 OK` |
| `GET` | `/certificates/{id}` | Bearer | Certificate details | `200 OK`, `404 Not Found` |
| `GET` | `/certificates/verify/{code}` | None | Public certificate verification | `200 OK`, `404 Not Found` |
| `POST` | `/certificates/issue/{path_id}` | Bearer | Issue certificate upon 100% completion | `200 OK`, `400 Bad Request` |

---

## 7. Skill Passport (`/passport`)

| Method | Endpoint | Auth | Purpose | Status Codes |
|---|---|---|---|---|
| `GET` | `/passport/me` | Bearer | Full private Skill Passport | `200 OK` |
| `GET` | `/passport/user/{user_id}` | None/Bearer | Public Skill Passport (privacy-redacted) | `200 OK`, `404 Not Found` |

---

## 8. Skill Intelligence (`/recommendations`)

| Method | Endpoint | Auth | Purpose | Status Codes |
|---|---|---|---|---|
| `GET` | `/recommendations/` | Bearer | AI match recommendations | `200 OK` |
| `GET` | `/recommendations/matches` | Bearer | Alias for AI matches | `200 OK` |

---

## 9. Community (`/community`)

| Method | Endpoint | Auth | Purpose | Status Codes |
|---|---|---|---|---|
| `GET` | `/community/discovery` | Bearer | Categorized peer discovery | `200 OK` |
| `GET` | `/community/activity` | None/Bearer | Live global activity feed | `200 OK` |
| `GET` | `/community/feed` | None/Bearer | Alias for global feed | `200 OK` |
| `GET` | `/community/profile/{id}` | Bearer | Public trust profile | `200 OK`, `404 Not Found` |
| `GET` | `/community/trust/{id}` | Bearer | Alias for trust profile | `200 OK`, `404 Not Found` |

---

## 10. Safety (`/safety`)

| Method | Endpoint | Auth | Purpose | Status Codes |
|---|---|---|---|---|
| `POST` | `/safety/report` | Bearer | Submit user safety report | `200 OK`, `400 Bad Request` |
| `POST` | `/safety/block/{id}` | Bearer | Block user | `200 OK`, `400 Bad Request` |
| `DELETE` | `/safety/block/{id}` | Bearer | Unblock user | `200 OK`, `404 Not Found` |
| `GET` | `/safety/blocks` | Bearer | List blocked user IDs | `200 OK` |

---

## 11. Bookings (`/bookings`)

| Method | Endpoint | Auth | Purpose | Status Codes |
|---|---|---|---|---|
| `GET` | `/bookings/` | Bearer | List user bookings | `200 OK` |
| `POST` | `/bookings/` | Bearer | Create booking & escrow credits | `200 OK`, `400 Bad Request` |
| `POST` | `/bookings/{id}/accept` | Bearer | Mentor accepts booking | `200 OK`, `400 Bad Request` |
| `POST` | `/bookings/{id}/reject` | Bearer | Mentor rejects booking & refunds | `200 OK`, `400 Bad Request` |
| `POST` | `/bookings/{id}/complete` | Bearer | Complete exchange & release credits | `200 OK`, `400 Bad Request` |

---

## 12. Wallet (`/wallet`)

| Method | Endpoint | Auth | Purpose | Status Codes |
|---|---|---|---|---|
| `GET` | `/wallet` | Bearer | Get wallet balance | `200 OK` |
| `GET` | `/wallet/transactions` | Bearer | Transaction history | `200 OK` |
| `GET` | `/wallet/transactions/{id}` | Bearer | Transaction details | `200 OK`, `404 Not Found` |

---

## 13. Reviews (`/reviews`)

| Method | Endpoint | Auth | Purpose | Status Codes |
|---|---|---|---|---|
| `POST` | `/reviews/` | Bearer | Submit session review (prevents duplicate) | `200 OK`, `400 Bad Request` |
| `GET` | `/reviews/user/{id}` | None | List reviews for user | `200 OK` |

---

## 14. Chat (`/chat`, `/chats`, `/messages`)

| Method | Endpoint | Auth | Purpose | Status Codes |
|---|---|---|---|---|
| `GET` | `/chats` | Bearer | List user active conversations | `200 OK` |
| `GET` | `/chats/{chat_id}` | Bearer | Conversation detail summary | `200 OK`, `404 Not Found` |
| `GET` | `/chats/{chat_id}/messages` | Bearer | Chat history for conversation | `200 OK` |
| `DELETE` | `/messages/{message_id}` | Bearer | Delete message | `200 OK` |
| `WS` | `/chat/ws?token=***` | Token Query | Real-time WebSocket channel | `101 Switching Protocols` |

---

## 15. Notifications (`/notifications`)

| Method | Endpoint | Auth | Purpose | Status Codes |
|---|---|---|---|---|
| `GET` | `/notifications/` | Bearer | List inbox notifications | `200 OK` |
| `POST` | `/notifications/{id}/read` | Bearer | Mark notification read | `200 OK` |
| `POST` | `/notifications/read-all` | Bearer | Mark all notifications read | `200 OK` |
| `DELETE` | `/notifications/{id}` | Bearer | Delete notification | `200 OK` |
| `DELETE` | `/notifications/` | Bearer | Bulk clear notifications | `200 OK` |

---

## 16. Gamification (`/gamification`)

| Method | Endpoint | Auth | Purpose | Status Codes |
|---|---|---|---|---|
| `GET` | `/gamification/dashboard` | Bearer | Gamification dashboard stats | `200 OK` |
| `GET` | `/gamification/achievements` | Bearer | List achievements & unlock status | `200 OK` |
| `GET` | `/gamification/leaderboard` | Bearer | Privacy-safe learner leaderboard | `200 OK` |
| `GET` | `/gamification/timeline/{id}` | Bearer | Chronological growth timeline | `200 OK` |

---

## 17. Admin Dashboard (`/admin`)

| Method | Endpoint | Auth | Purpose | Status Codes |
|---|---|---|---|---|
| `GET` | `/admin/stats` | Admin | System statistics overview | `200 OK`, `403 Forbidden` |
| `GET` | `/admin/users` | Admin | Manage system users | `200 OK`, `403 Forbidden` |
| `GET` | `/admin/reports` | Admin | List safety reports | `200 OK`, `403 Forbidden` |
| `POST` | `/admin/reports/{id}/status` | Admin | Moderate safety report | `200 OK`, `403 Forbidden` |
