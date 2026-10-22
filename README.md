# Local Skill Exchange

> **A Hyperlocal, Gamified & AI-Driven Peer-to-Peer Skill Swapping Platform**  
> *Developed for Master of Computer Applications (MCA) Final Project Submission*

---

## 📋 Table of Contents
- [Project Overview](#-project-overview)
- [Problem Statement](#-problem-statement)
- [Proposed Solution](#-proposed-solution)
- [Key Features](#-key-features)
- [Technology Stack](#-technology-stack)
- [System Architecture](#-system-architecture)
- [Core Product Workflow](#-core-product-workflow)
- [Database Schema (MySQL)](#-database-schema-mysql)
- [AI & Intelligence Components](#-ai--intelligence-components)
- [Security & Privacy Implementation](#-security--privacy-implementation)
- [Installation & Setup Guide](#-installation--setup-guide)
- [API Documentation Reference](#-api-documentation-reference)
- [Project Directory Structure](#-project-directory-structure)
- [Screenshots & Visual Gallery](#-screenshots--visual-gallery)
- [Future Scope](#-future-scope)
- [Known Limitations](#-known-limitations)
- [Documentation Index](#-documentation-index)

---

## 🚀 Project Overview

**Local Skill Exchange** is a community-driven, barter-based learning platform that connects local community members to learn, practice, certify, and swap skills 1-on-1 without any financial cost. The system combines an interactive **Learning Hub** with server-evaluated assessments, tamper-proof **Verified Digital Certificates**, an aggregated **Skill Passport**, **Explainable AI Match Recommendations**, **Real-Time WebSocket Chat**, an **Escrow Credit Wallet**, and a **Deduplicated Gamification Engine** (XP, Levels, Streaks, Achievements, and Privacy-Safe Leaderboards).

---

## 🎯 Problem Statement

1. **High Financial Barrier:** Commercial EdTech platforms (Udemy, LinkedIn Learning, private tutors) charge expensive course fees or subscription costs, making skill learning inaccessible to many.
2. **Passive Consumption:** Video-only courses lack interactive 1-on-1 peer mentoring and practical hands-on evaluation.
3. **Lack of Hyperlocal Community:** Learners rarely connect with knowledgeable individuals living in their immediate geographic neighborhood.
4. **Unverifiable Informal Skills:** Skills acquired outside formal universities lack verifiable, privacy-safe credentials.

---

## 💡 Proposed Solution

The **Local Skill Exchange** platform provides a comprehensive barter-based ecosystem:
- **Zero Financial Cost:** Users earn credits by teaching others or completing learning assessments, which can then be spent to book 1-on-1 sessions with local mentors.
- **Interactive Practice & Server Scoring:** Quizzes evaluate student comprehension server-side with zero answer leaks.
- **Tamper-Proof Certificates:** Issued upon path completion with unique verification numbers for public authenticity validation.
- **Digital Skill Passport:** Aggregates user achievements, verified certificates, and exchange statistics into a single verifiable profile.
- **Explainable AI Matching:** Multi-factor scoring matches learners with optimal mentors based on proximity, ratings, review volume, and learning goals.

---

## ✨ Key Features

- **Personal AI Skill Growth Engine:** Tracks historical quiz accuracy, growth velocity, composite Mastery Index (0–100), weak topic diagnostics, adaptive next steps, and two-way reciprocal mentor matches.
- **AI Skill Coach Hub (`/ai-coach-hub`):** 9-section intelligent dashboard featuring dynamic daily objectives with XP bounties, weekly AI insights, and personalized learning roadmaps.
- **Interactive Learning Hub:** Structured curriculum tree (`Skill` ──► `LearningPath` ──► `Lesson` ──► `PracticeQuestion`).
- **Server-Side Evaluated Practice:** Interactive multiple-choice quizzes scored server-side with zero client-side answer leaks.
- **Verified Certificates:** Unique certificate codes (`LSE-CERT-2026-00001-9E2A`) publicly verifiable without login.
- **Digital Skill Passport:** Aggregates certified skills, badges, and learning milestones with privacy redaction on public profiles.
- **AI Match Engine:** Multi-factor algorithm evaluating Haversine distance, mentor star rating, review volume, and curriculum alignment.
- **Credit Escrow Wallet:** Automated credit hold upon booking reservation, released to mentor upon session completion.
- **Real-Time WebSocket Messaging:** Instant 1-on-1 messaging with online status indicators.
- **Gamification Engine:** Deduplicated XP awards, 5-tier level progression, real activity streak calculation, unlocked achievements, and a privacy-safe community leaderboard.
- **Community Safety & Moderation:** User reporting, bilateral blocking, and an Admin moderation portal.

---

## 🛠️ Technology Stack

| Layer | Technology | Usage / Purpose |
|---|---|---|
| **Frontend Framework** | **Flutter** (Dart 3.x) | Cross-platform UI for Web, Android, iOS & Desktop |
| **State Management** | **Flutter Riverpod** | Reactive, compile-safe state management |
| **HTTP Client** | **Dio** | API Client with JWT interceptors and error handling |
| **Real-Time Messaging** | **WebSocketChannel** | Persistent bidirectional WebSocket connection |
| **Location & Maps** | **Google Maps Flutter SDK** | Map visualization and geolocations |
| **Backend Framework** | **FastAPI** (Python 3.11+) | Async ASGI REST API server |
| **ASGI Web Server** | **Uvicorn** | Lightning-fast ASGI web server |
| **ORM Layer** | **SQLAlchemy 2.0+** | Object-Relational Mapping & connection pooling |
| **Database Server** | **MySQL 8.0** | Relational Database (`local_skill_exchange`) |
| **Database Driver** | **PyMySQL** | MySQL Python driver |
| **Security & JWT** | **PyJWT & Passlib (bcrypt)** | Password hashing & signed JWT Bearer Tokens |

---

## 🏗️ System Architecture

```
+-------------------------------------------------------------------+
|                        Flutter Frontend App                       |
|           (Mobile / Web / Desktop - Riverpod, Dio, WebSockets)    |
+-------------------------------------------------------------------+
                                  │
            REST APIs (HTTP/JSON) │ Real-Time WebSocket (ws://)
                                  ▼
+-------------------------------------------------------------------+
|                        FastAPI Backend Server                     |
|           (Python 3.11+ / Uvicorn ASGI / Security / JWT)          |
+-------------------------------------------------------------------+
                                  │
                          SQLAlchemy ORM
                                  ▼
+-------------------------------------------------------------------+
|                        MySQL Database Server                      |
|                  (localhost:3306/local_skill_exchange)            |
+-------------------------------------------------------------------+
```

---

## 🔄 Core Product Workflow

```
DISCOVER SKILL (Catalog / Search)
       │
       ▼
START LEARNING PATH (Curriculum Tree)
       │
       ▼
COMPLETE LESSONS & TAKE PRACTICE QUIZ (Server Evaluation)
       │
       ▼
EARN XP & UNLOCK ACHIEVEMENTS (Deduplicated XP Logs)
       │
       ▼
ISSUE VERIFIED CERTIFICATE (Public Validation Code)
       │
       ▼
BUILD DIGITAL SKILL PASSPORT (Aggregated Profile)
       │
       ▼
DISCOVER MENTORS (AI Match Recommendations / Maps)
       │
       ▼
BOOK EXCHANGE SESSION (Escrowed Wallet Credits)
       │
       ▼
REAL-TIME CHAT & COMPLETE SESSION
       │
       ▼
SUBMIT VERIFIED REVIEW & GROW (Leaderboard Ranking)
```

---

## 🗄️ Database Schema (MySQL)

The application communicates exclusively with MySQL Server database `local_skill_exchange` on `localhost:3306` containing 21 relational tables:

```mermaid
erDiagram
    users ||--o{ user_skills_offered : "offers"
    users ||--o{ user_skills_wanted : "wants"
    users ||--o{ user_learning_progress : "tracks"
    users ||--o{ practice_attempts : "completes"
    users ||--o{ certificates : "earns"
    users ||--o{ bookings : "initiates/hosts"
    users ||--o{ reviews : "writes/receives"
    users ||--o{ transactions : "logs"
    users ||--o{ notifications : "receives"
    users ||--o{ user_achievements : "unlocks"
    users ||--o{ user_xp_logs : "records"
    users ||--o{ user_reports : "submits/receives"
    users ||--o{ user_blocks : "blocks"
    
    skills ||--o{ learning_paths : "defines"
    skills ||--o{ user_skills_offered : "categorizes"
    skills ||--o{ user_skills_wanted : "categorizes"
    
    learning_paths ||--o{ lessons : "contains"
    learning_paths ||--o{ certificates : "issues"
    
    lessons ||--o{ practice_questions : "includes"
    lessons ||--o{ practice_attempts : "evaluates"
```

---

## 🤖 AI & Intelligence Components

The recommendation engine (`GET /api/v1/recommendations/matches`) computes a personalized match score (0–100%) for candidate mentors using a 4-weighted hybrid model:

1. **Mentor Star Rating (40% Weight):** Scaled average star rating.
2. **Review Volume (20% Weight):** Logarithmic scaling of verified reviews.
3. **Proximity Score (20% Weight):** Great-circle distance calculated via Haversine Formula:
   $$d = 2R \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta\phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta\lambda}{2}\right)}\right)$$
4. **Curriculum Alignment (20% Weight):** Match between mentor's offered skills and learner's wanted or currently enrolled learning path skills.

---

## 🔒 Security & Privacy Implementation

- **Password Hashing:** Passwords hashed with bcrypt before database persistence.
- **Signed JWT Authentication:** Tokens expire after 7 days; validated on every protected API call.
- **Role-Based Access Control (RBAC):** Admin routes (`/admin/*`) strictly verify `current_user.is_admin == True`.
- **Token Masking:** Log outputs mask sensitive JWT query parameters (`debugPrint('.../chat/ws?token=***')`).
- **Privacy Redaction:** Public profile views (`/passport/user/{id}`, `/community/trust/{id}`) omit sensitive attributes (`email`, `hashed_password`, `credits`).
- **Zero Cheat Vector:** Practice answers scored server-side; correct answers never exposed in GET quiz payloads.

---

## ⚡ Installation & Setup Guide

### 1. Prerequisites
- Python 3.11+
- Flutter SDK 3.29+
- MySQL Server 8.0+ running on `localhost:3306`

### 2. MySQL Configuration
```sql
CREATE DATABASE local_skill_exchange CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3. Backend Setup
```bash
# Clone the repository
git clone https://github.com/your-username/Local_Skill_Exchange.git
cd Local_Skill_Exchange

# Configure environment variables
cp .env.example .env

# Edit .env and set your local MySQL password and JWT secret:
# DATABASE_URL=mysql+pymysql://root:YOUR_MYSQL_PASSWORD@localhost:3306/local_skill_exchange
# SECRET_KEY=YOUR_JWT_SECRET_KEY

# Install dependencies
pip install -r requirements.txt # or install fastapi uvicorn sqlalchemy pymysql pydantic pydantic-settings pyjwt passlib[bcrypt] python-dotenv

# Run FastAPI backend server
python -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 --reload
```

### 4. Frontend Setup
```bash
# Fetch dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run on Web (Chrome)
flutter run -d chrome
```

---

## 🌐 Production Readiness & Cloud Deployment

### 1. Standalone Cloud Deployment (Zero Laptop Dependency)
The backend and MySQL database can be deployed autonomously to the cloud using the included blueprints:

- **Railway (Recommended 1-Click):**
  - Uses `railway.json` and `backend/Dockerfile`.
  - Connect your GitHub repo to Railway, provision a MySQL service and a Web service from Dockerfile.
  - Set `INIT_SEEDS=true` and `ENVIRONMENT=production`.
  - Railway provides automatic HTTPS: `https://your-app.up.railway.app`.

- **Render:**
  - Uses `render.yaml` infrastructure blueprint.
  - Creates the web service and managed MySQL database with auto-generated SSL and health probes (`/health`).

- **Self-Hosted Docker Compose:**
  - Run on any VPS (AWS EC2, DigitalOcean, Linode):
  ```bash
  docker compose -f docker-compose.prod.yml up -d --build
  ```

### 2. Runtime Mobile API Endpoint Configuration
Mobile users can connect to any deployed cloud backend without re-compiling the APK:
1. Tap the **Server URL** settings button on the Login / Splash screen.
2. Enter your production HTTPS URL (e.g., `https://your-app.up.railway.app/api/v1`).
3. The app validates the connection and saves it securely to encrypted device storage.

### 3. Production Security & Concurrency Protections
- **Wallet Concurrency (Double-Spending Prevention):** Atomic database credit decrements with credit floor checks (`WHERE credits >= cost`) ensure concurrent requests never result in negative balances.
- **Strict SECRET_KEY Enforcement:** When `ENVIRONMENT=production`, the server strictly rejects default or missing JWT signing keys.
- **Upload Validation:** Avatar uploads enforce a 5 MB ceiling and strict magic-byte file signature validation (JPEG, PNG, WebP, GIF), blocking arbitrary binaries.
- **Database Performance:** 27 foreign keys, timestamps, and filter columns are indexed across all tables to eliminate full table scans.

### 4. Database Backups & Index Migrations
- **Backup Snapshot Utility:**
  ```bash
  python backend/scripts/backup_db.py
  ```
  Generates timestamped SQL dump archives in `backend/backups/`.
- **Performance Index Migration:**
  ```bash
  python backend/scripts/apply_indexes.py
  ```

### 5. Automated Regression Test Suites
```bash
# Test backend authentication flows (Register, Form/JSON Login, Guest, Google OAuth)
python backend/scripts/test_auth_flows.py

# Test critical production fixes (Wallet concurrency, upload security, secret enforcement)
python backend/scripts/test_critical_fixes.py

# Run Flutter automated test suite
flutter test

# Run Flutter static code analysis
flutter analyze
```

---

## 📚 API Documentation Reference

FastAPI automatically generates interactive API documentation:
- **Swagger UI:** `http://127.0.0.1:8000/docs`
- **ReDoc:** `http://127.0.0.1:8000/redoc`

Detailed endpoint references across all 17 API groups are documented in [docs/api.md](docs/api.md).

---

## 📁 Project Directory Structure

```
Local_Skill_Exchange/
├── .env.example                 # Environment variables template
├── README.md                     # Main documentation & setup guide
├── verification_report.md        # Formal multi-phase verification report
├── walkthrough.md                # Development phase walkthrough log
├── docs/                         # Comprehensive Project Documentation Suite
│   ├── architecture.md           # System architecture & request flows
│   ├── api.md                    # REST API reference documentation
│   ├── setup.md                  # Machine setup & deployment guide
│   ├── testing.md                # QA testing strategy & smoke test logs
│   ├── mca_presentation.md       # Presentation slide deck material
│   ├── viva_questions.md         # Viva Voce Q&A preparation
│   ├── demo_script.md            # 5-10 minute demonstration script
│   ├── project_structure.md      # Detailed project tree reference
│   └── project_status.md         # Final completion matrix
├── backend/                      # FastAPI Python Backend
│   ├── app/
│   │   ├── main.py               # FastAPI application entry point
│   │   ├── api/routes/           # 17 API Router modules
│   │   ├── core/                 # Config & Security utilities
│   │   ├── db/                   # Database engine & 21 ORM models
│   │   ├── schemas/              # Pydantic validation models
│   │   └── services/             # Business logic layer
└── lib/                          # Flutter Frontend Application
    ├── main.dart                 # App entry point
    ├── models/                   # Data models
    ├── providers/                # Riverpod providers
    ├── repositories/             # Dio API repositories
    ├── routes/                   # AppRoutes navigation
    ├── screens/                  # Feature views & UI screens
    ├── services/                 # WebSocket & Auth singletons
    └── widgets/                  # Shared UI components
```

---

## 📸 Screenshots & Visual Gallery

| Screen | Description | Location / Reference |
|---|---|---|
| **Home Dashboard** | Level progress, streak counter, AI Coach card & learning progress | `lib/screens/home_screen.dart` |
| **AI Coach Hub** | 9-section Personal AI Skill Growth Engine & Daily Objectives | `lib/screens/features/ai_coach_hub_screen.dart` |
| **Learning Hub** | Curriculum paths, lesson views & ordered course tree | `lib/screens/learning/learning_hub_screen.dart` |
| **Practice Quiz** | Server-evaluated interactive quiz with explanations | `lib/screens/learning/practice_screen.dart` |
| **Certificates** | Verifiable credentials & public validation modal | `lib/screens/certificates/certificates_screen.dart` |
| **Skill Passport** | Aggregated masteries, badges & growth timeline | `lib/screens/passport/skill_passport_screen.dart` |
| **AI Match & Maps** | Hyperlocal mentor discovery & explainable AI scores | `lib/screens/explore_screen.dart` |
| **Leaderboard** | Privacy-safe learner rankings & XP badges | `lib/screens/gamification/leaderboard_screen.dart` |
| **Admin Dashboard** | System analytics & safety reports moderation | `lib/screens/admin/admin_dashboard_screen.dart` |

---

## 🔮 Future Scope

- Integration of native WebRTC video calls inside 1-on-1 exchange sessions.
- Mobile Push Notifications via Firebase Cloud Messaging (FCM).
- AI automated tutor chatbot for instant interactive practice assistance.

---

## ⚠️ Known Limitations

1. **Local Development Build:** Verified on local development machine environment (`localhost:3306` MySQL, `127.0.0.1:8000` FastAPI, Chrome Web). Production cloud hosting setup scripts provided in `docs/setup.md`.
2. **Session Video Calls:** Exchange bookings and escrow credits execute seamlessly; live video sessions currently rely on chat coordination.

---

## 📖 Documentation Index

For exhaustive technical references, please inspect the `docs/` directory:
- [docs/architecture.md](docs/architecture.md) — System Architecture & Data Flow
- [docs/api.md](docs/api.md) — REST API Documentation
- [docs/setup.md](docs/setup.md) — Setup & Installation Guide
- [docs/testing.md](docs/testing.md) — QA & Testing Documentation
- [docs/mca_presentation.md](docs/mca_presentation.md) — MCA Presentation Material
- [docs/viva_questions.md](docs/viva_questions.md) — Viva Voce Q&A Guide
- [docs/demo_script.md](docs/demo_script.md) — Demonstration Script
- [docs/project_structure.md](docs/project_structure.md) — Directory Structure
- [docs/project_status.md](docs/project_status.md) — Project Status Matrix
- [verification_report.md](verification_report.md) — Multi-Phase Verification Report
- [walkthrough.md](walkthrough.md) — Phase Log Walkthrough
