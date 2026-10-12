# System Architecture Documentation — Local Skill Exchange

## 1. Executive Summary

The **Local Skill Exchange** platform is built on a modern, decoupled client-server architecture designed for high scalability, real-time interactivity, and strong data privacy.

```
+-------------------------------------------------------------------+
|                        Flutter Frontend App                       |
|           (Mobile / Web / Desktop - Riverpod, Dio, WebSockets)    |
+-------------------------------------------------------------------+
                                  |
            REST APIs (HTTP/JSON) | Real-Time WebSocket (ws://)
                                  v
+-------------------------------------------------------------------+
|                        FastAPI Backend Server                     |
|           (Python 3.11+ / Uvicorn ASGI / Security / JWT)          |
+-------------------------------------------------------------------+
                                  |
                          SQLAlchemy ORM
                                  v
+-------------------------------------------------------------------+
|                        MySQL Database Server                      |
|                  (localhost:3306/local_skill_exchange)            |
+-------------------------------------------------------------------+
```

---

## 2. Technology Stack Overview

### 2.1 Frontend (Client Application)
- **Framework:** Flutter (Web, Mobile, Desktop)
- **State Management:** Flutter Riverpod (`StateNotifierProvider`, `FutureProvider`, `Provider`)
- **HTTP Client:** Dio (with `ApiClient` singleton, authorization header interceptor, error handling)
- **Real-time Engine:** `WebSocketChannel` with automatic reconnect and ping/pong heartbeats
- **Secure Storage:** `FlutterSecureStorage` (JWT access token persistence)
- **Location Services:** `google_maps_flutter_web` & `geolocator`

### 2.2 Backend (API Server)
- **Framework:** FastAPI (Python 3.11+) running on Uvicorn ASGI server
- **Authentication:** OAuth2 Password Bearer flow with JWT (JSON Web Tokens) using `pyjwt` & `passlib` (bcrypt)
- **ORM & Database Abstraction:** SQLAlchemy 2.0+ with connection pooling (`pool_pre_ping=True`, `pool_recycle=3600`)
- **Validation & Schemas:** Pydantic V2 (`from_attributes = True`)
- **Real-time Messaging:** FastAPI WebSocket router with in-memory `ConnectionManager`

### 2.3 Database
- **RDBMS:** MySQL Server (Database: `local_skill_exchange` on `localhost:3306`)
- **Driver:** PyMySQL (`mysql+pymysql`)

---

## 3. Request Lifecycle & End-to-End Data Flow

### 3.1 Synchronous REST Request Flow
```
[Flutter UI Widget] 
       │
       ▼
[Riverpod Provider / Repository]
       │
       ▼
[ApiClient (Dio)] ─── (Attaches 'Authorization: Bearer <JWT>') ───► [FastAPI Router]
                                                                        │
                                                                        ▼
                                                             [Dependency Injection (CurrentUser)]
                                                                        │
                                                                        ▼
                                                             [Service / Business Logic]
                                                                        │
                                                                        ▼
                                                             [SQLAlchemy ORM Session]
                                                                        │
                                                                        ▼
[Flutter UI updates] ◄─── [Pydantic Response Schema] ◄─── [MySQL Engine Execution]
```

### 3.2 Real-Time WebSocket Chat Flow
```
[User A (Sender)] ───► [WebSocket Channel] ───► [FastAPI /chat/ws?token=***]
                                                        │
                                                        ├─► Validates JWT Token
                                                        ├─► Persists Message to MySQL (`messages` table)
                                                        └─► Delivers to User B ConnectionManager
                                                                    │
                                                                    ▼
                                                            [User B (Receiver)]
```

---

## 4. Subsystem Architecture

### 4.1 Authentication & Authorization Subsystem
- **Endpoints:** `/api/v1/auth/register`, `/api/v1/auth/login`
- **Tokens:** Form-urlencoded login returns a signed JWT bearer token stored in `FlutterSecureStorage`.
- **Protection:** FastAPI `Depends(get_current_user)` validates tokens on every protected route. Admin routes verify `current_user.is_admin == True`.

### 4.2 Learning & Practice Subsystem
- **Curriculum Tree:** `Skill` ──► `LearningPath` ──► `Lesson` ──► `PracticeQuestion`
- **Server-Side Practice Evaluation:** Client submits answer IDs (`POST /learning/lessons/{id}/practice/submit`). Backend scores submission, logs `PracticeAttempt`, and awards deduplicated XP.
- **Answer Security:** `correct_answer` is strictly stripped from all GET responses.

### 4.3 Certification & Skill Passport Subsystem
- **Issuance:** 100% path completion triggers automated certificate generation with unique `certificate_number` (e.g. `LSE-CERT-2026-00001-9E2A`) and `verification_code`.
- **Skill Passport:** Dynamically aggregates learning progress, practice accuracy, earned certificates, and verified exchange counts into a single verifiable profile (`/api/v1/passport/me`).
- **Privacy Redaction:** Public views (`/api/v1/passport/user/{id}`) redact email addresses, passwords, and credit balances.

### 4.4 AI Match & Intelligence Subsystem
- **Algorithmic Scoring:** Multi-factor matching engine evaluates proximity (Haversine formula), mentor rating, review count, and curriculum alignment to generate a match score (0–100%).

### 4.5 Community, Trust & Safety Subsystem
- **Trust Indicators:** Computes verified certificates, completed exchanges, and rating averages.
- **Safety & Moderation:** Features user reporting (`POST /safety/report`), blocking (`POST /safety/block/{id}`), and admin moderation portal.

### 4.6 Gamification Subsystem
- **XP & Levels:** Transparent level thresholds (Novice, Apprentice, Practitioner, Master, Grandmaster).
- **Idempotency:** XP awards logged in `user_xp_logs` with unique `(user_id, action_key)` constraints to prevent duplication.
- **Learning Streak:** Consecutive activity calculation derived strictly from real database timestamps.
