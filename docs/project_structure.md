# Project Directory Structure — Local Skill Exchange

```
Local_Skill_Exchange/
│
├── .env.example                 # Secure template for environment variables
├── .gitignore                    # Exclusion rules for secrets, builds, and dependencies
├── pubspec.yaml                  # Flutter package dependencies and assets config
├── README.md                     # Main GitHub & MCA project documentation
├── verification_report.md        # Comprehensive multi-phase verification report
├── walkthrough.md                # Development phase walkthrough log
│
├── docs/                         # Project Documentation Suite
│   ├── architecture.md           # System architecture, request flow & WebSockets
│   ├── api.md                    # Complete REST API reference (17 groups)
│   ├── setup.md                  # Machine setup & installation guide
│   ├── testing.md                # QA testing strategy, positive/negative tests
│   ├── mca_presentation.md       # MCA final project presentation slides material
│   ├── viva_questions.md         # Comprehensive viva Q&A guide
│   ├── demo_script.md            # 5-10 minute project demonstration walkthrough
│   ├── project_structure.md      # Exact directory structure documentation
│   └── project_status.md         # Final completion status & feature matrix
│
├── backend/                      # FastAPI Python Backend
│   ├── app/
│   │   ├── main.py               # FastAPI application initialization & route inclusions
│   │   ├── api/
│   │   │   ├── deps.py           # Dependency injection (SessionDep, CurrentUser)
│   │   │   └── routes/           # API Routers
│   │   │       ├── admin.py           # Admin stats, user management & moderation
│   │   │       ├── auth.py            # User registration & OAuth2 JWT login
│   │   │       ├── bookings.py        # Booking lifecycle & credit escrow
│   │   │       ├── certificates.py    # Certification issuance & verification
│   │   │       ├── chat.py            # Real-time WebSocket chat & messaging
│   │   │       ├── community.py       # Activity feed, discovery & trust profiles
│   │   │       ├── gamification.py    # XP, levels, achievements & leaderboard
│   │   │       ├── learning.py        # Paths, lessons & server-scored practice
│   │   │       ├── notifications.py   # Inbox notifications & deletion routes
│   │   │       ├── passport.py        # Digital Skill Passport endpoints
│   │   │       ├── recommendations.py # AI personalized match recommendations
│   │   │       ├── reviews.py         # Verified session reviews & rating updates
│   │   │       ├── safety.py          # Safety reporting, blocking & unblocking
│   │   │       ├── skills.py          # Skills catalog, offered & wanted skills
│   │   │       ├── users.py           # Profile management & nearby mentors
│   │   │       └── wallet.py          # Wallet balance & transaction history
│   │   ├── core/
│   │   │   ├── config.py         # System configuration & environment loading
│   │   │   └── security.py       # Password hashing (bcrypt) & JWT token utilities
│   │   ├── db/
│   │   │   ├── database.py       # SQLAlchemy engine & MySQL connection pool setup
│   │   │   └── models.py         # SQLAlchemy ORM database models (21 tables)
│   │   ├── schemas/              # Pydantic schemas for data validation
│   │   └── services/             # Business logic layer
│   └── scripts/                  # Data seeding scripts
│
└── lib/                          # Flutter Frontend Application
    ├── main.dart                 # Application entry point & theme configuration
    ├── core/                     # Common core utilities & widgets
    │   ├── network/              # Token storage & API client bindings
    │   └── widgets/              # Avatar, loading, empty & error states
    ├── models/                   # Data models matching backend Pydantic schemas
    ├── providers/                # Riverpod state management providers
    ├── repositories/             # API data repositories handling Dio HTTP calls
    ├── routes/                   # AppRoutes named navigation & route generator
    ├── screens/                  # Application Screens & Feature Views
    │   ├── admin/                # Admin Dashboard & Moderation portal
    │   ├── auth/                 # Login, Register & Forgot Password screens
    │   ├── certificates/         # Certificates List, Detail & Verification
    │   ├── features/             # Notifications, Wallet, AI Match, Mentor Profile
    │   ├── gamification/         # Privacy-safe Leaderboard
    │   ├── learning/             # Learning Hub, Lesson view & Practice quiz
    │   ├── passport/             # Digital Skill Passport screen
    │   └── splash/               # Splash & Onboarding screens
    ├── services/                 # WebSocketManager & AuthService singletons
    └── widgets/                  # Modular home, explore & learning widgets
```
