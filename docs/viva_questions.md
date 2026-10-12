# MCA Viva Questions & Answers — Local Skill Exchange

This comprehensive guide contains detailed technical viva questions and verified answers covering every architectural, algorithmic, database, and security aspect of the project for the MCA final viva defense.

---

## 1. Project Overview & Architecture

### Q1: What is the core problem solved by Local Skill Exchange?
**A:** Commercial online courses are expensive and passive. Local Skill Exchange provides a zero-cost barter-based platform where users can learn skills through interactive learning paths, practice with server-evaluated quizzes, earn verifiable digital certificates, and exchange 1-on-1 skills with local community mentors using an escrowed credit wallet.

### Q2: What is the high-level architecture of the application?
**A:** It is a modern three-tier decoupled architecture:
1. **Presentation Tier:** Flutter (Web & Android) utilizing Riverpod for reactive state management, Dio with JWT interceptors for REST APIs, and native WebSocket channels for real-time chat.
2. **Application Tier:** FastAPI (Python 3.12+) running on Uvicorn ASGI server with Pydantic v2 schemas, OAuth2 JWT authentication, and modular service layers (AI Coach, Gamification, Escrow, Safety).
3. **Database Tier:** MySQL 8.0 with SQLAlchemy ORM, 21 relational tables with foreign key constraints, connection pool recycling, and ACID transactions.

---

## 2. Artificial Intelligence & Adaptive Learning

### Q3: How does the Personal AI Skill Growth Engine work without paid third-party AI APIs?
**A:** The engine operates deterministically and mathematically over real database records:
1. **Growth & Velocity Tracking:** Compares historical initial quiz scores with latest quiz attempts to calculate percentage improvement and determine velocity trends (*Improving*, *Mastered*, *Steady*, *Needs Attention*).
2. **Composite Mastery Index (0–100):** Combines certificate achievements (up to 40 pts), quiz accuracy average (up to 30 pts), and learning path progress (up to 30 pts).
3. **Smart Practice Diagnostics:** Detects lessons where accuracy $< 70\%$ and flags them for targeted concept revision.
4. **Adaptive Learning Steps:** Categorizes immediate next actions: `CONTINUE_LEARNING`, `REVIEW_TOPIC`, `PRACTICE_QUIZ`, `LEARN_NEXT`, `PREPARE_CERTIFICATION` based on user milestones.
5. **Two-Way Reciprocal Matching:** Identifies bidirectional swaps ($\text{User A teaches X/wants Y} \leftrightarrow \text{User B teaches Y/wants X}$) to optimize barter efficiency.

### Q4: What is the mathematical formula for the multi-factor AI Mentor Compatibility Score?
**A:** The compatibility score $S \in [0, 100]$ is calculated as:
$$S = 0.40 \cdot S_{\text{skill}} + 0.25 \cdot S_{\text{reciprocal}} + 0.15 \cdot S_{\text{rating}} + 0.10 \cdot S_{\text{experience}} + 0.10 \cdot S_{\text{proximity}}$$
Where:
- $S_{\text{skill}}$: Direct skill wanted-to-offered overlap (100 if matching, 50 if general category).
- $S_{\text{reciprocal}}$: 100 if the candidate also wants a skill that the user offers (two-way match), else 0.
- $S_{\text{rating}}$: Normalized mentor star rating ($\frac{\text{Rating}}{5.0} \times 100$).
- $S_{\text{experience}}$: Logarithmic scaling based on completed mentor sessions ($\min(100, \text{sessions} \times 10)$).
- $S_{\text{proximity}}$: Linear proximity decay ($\max(0, 100 - \text{distance\_km} \times 2)$).

### Q5: How is geographical distance calculated between users?
**A:** Using the **Haversine Distance Formula** on coordinates (latitude/longitude) stored in MySQL:
$$d = 2R \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta \phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta \lambda}{2}\right)}\right)$$
Where $R = 6371\text{ km}$, $\Delta \phi$ is difference in latitude, and $\Delta \lambda$ is difference in longitude in radians.

---

## 3. Financial Integrity & Escrow Wallet

### Q6: How does the credit barter and escrow wallet system operate?
**A:** 
1. **Hold upon Booking:** When a mentee books a session costing $N$ credits, the backend verifies `mentee.credits >= N`. It deducts $N$ credits from mentee and creates the booking with status `upcoming`.
2. **Release upon Completion:** When the session is completed, $N$ credits are credited to the mentor, and double-entry transaction rows are inserted into `transactions` table.
3. **Refund on Cancellation:** If an upcoming session is cancelled, the $N$ credits are refunded back to the mentee with corresponding refund transaction logs.
4. **ACID Safety:** The entire credit adjustment and booking update occurs inside a single database transaction with explicit `db.commit()` and `db.rollback()` on exceptions.

---

## 4. Frontend & State Management

### Q7: Why Riverpod over Provider or Bloc?
**A:** Riverpod is compile-time safe (no runtime `ProviderNotFoundException`), is decoupled from Flutter's widget tree (can be accessed outside `BuildContext`), provides automatic disposal and caching with `autoDispose`, and cleanly handles loading and error states via `AsyncValue`.

### Q8: How does the frontend handle token authentication and automatic renewal?
**A:** `TokenStorage` stores the JWT securely using `FlutterSecureStorage` (backed by Keychain on iOS, KeyStore on Android, and Encrypted LocalStorage on Web). An interceptor on the `Dio` instance automatically injects `Authorization: Bearer <token>` into headers for every request and intercepts 401 responses to route users to the login screen.

---

## 5. Security, Verification & Quality Assurance

### Q9: How do you prevent quiz cheating and answer exposure?
**A:** Practice questions delivered to the frontend via `GET /learning/lessons/{id}/practice` omit the `correct_answer` column. When a user submits answers via `POST /learning/lessons/{id}/practice/submit`, the backend evaluates the submission against the database and awards scores and XP securely.

### Q10: How is XP farming and duplicate reward inflation prevented?
**A:** Gamification uses idempotent actions via `user_xp_logs`. Every award requires a unique `action_key` (e.g. `pass_practice_lesson_1_user_2`). `gamification_service.award_xp_idempotent` checks if the key already exists before granting XP or leveling up.

### Q11: How are certificates issued and verified publicly?
**A:** When all lessons in a learning path are completed, a certificate is generated with a cryptographic serial code formatted as `LSE-CERT-{YYYY}-{USER_ID:05d}-{HEX_HASH}`. Any recruiter or peer can verify authenticity publicly via `/certificates/verify/{certificate_number}` without logging in.

### Q12: What test suites verify the application?
**A:** 
1. **Full Backend Regression Suite:** 68 tests covering authentication, learning, quizzes, certificates, passport, bookings, reviews, and safety.
2. **Phase O AI Intelligence Suite:** 12 tests validating growth calculations, adaptive guidance, daily goals, and cold-start user handling.
3. **Phase P Production Excellence Suite:** 16 tests auditing security boundaries, non-admin role enforcement, and password non-exposure.
4. **Flutter Static Analysis:** 0 errors, 0 warnings across the entire frontend.
5. **Total Test Coverage:** 96/96 automated tests passing with 100% pass rate.
