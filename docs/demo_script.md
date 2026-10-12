# Project Demonstration Script — Local Skill Exchange

**Target Duration:** 8 to 12 minutes  
**Target Audience:** MCA External Examiner, Project Coordinator, Evaluation Committee

---

## Pre-Demo Setup Checklist
1. **Backend Server:** Running on `http://127.0.0.1:8000` (`python -m uvicorn app.main:app --reload`).
2. **Frontend Client:** Running on Chrome / Android (`flutter run -d chrome`).
3. **Demo User Accounts:**
   - **Primary Learner / Mentor:** `testuser@example.com` / `password` (Admin privileges enabled).
   - **Peer Mentor:** `user2@example.com` / `password`.

---

## Demo Step-by-Step Sequence

### 1. Introduction & Authentication (1 Minute)
- **Action:** Open application on Chrome browser.
- **Action:** Sign in with `testuser@example.com`.
- **Key Talking Points:** Explain modern decoupled architecture (Flutter + FastAPI + MySQL), OAuth2 password flow, and secure client-side JWT token storage.

### 2. Home Dashboard & AI Skill Coach Card (1.5 Minutes)
- **Action:** Highlight dynamic **AI Skill Coach Banner** on top of Home.
- **Action:** Show real-time context-aware state (*e.g., "Daily Goal: Revise Quiz on Python Programming"*).
- **Action:** Point out real-time streak counter (🔥 3 Days), level chip (Level 5), and wallet credit balance.
- **Key Talking Points:** Zero fake/mock data; every metric is derived dynamically from MySQL relational records.

### 3. Personal AI Skill Growth Engine Hub (2 Minutes)
- **Action:** Tap on the AI Coach banner to navigate to `/ai-coach-hub`.
- **Action:** Walk through the 9 specialized sections:
  1. **AI Daily Objective:** Dynamic goal with XP reward.
  2. **Weekly AI Growth Insights:** Lessons completed, quiz attempts, and accuracy gain.
  3. **Skill Growth Velocity & Mastery Index:** Composite score ($79/100$) combining certs, accuracy, and path completion.
  4. **Adaptive Learning Steps:** Categorized recommendations (`CONTINUE_LEARNING`, `REVIEW_TOPIC`, `PRACTICE_QUIZ`).
  5. **Smart Practice Diagnostics:** Concept weak points.
  6. **Skill-Gap Matrix:** Identified strengths vs needed skills.
  7. **Two-Way Reciprocal Matches:** Mentors where both parties can exchange complementary skills.
  8. **Intelligent Mentor Recommendations:** Multi-factor compatibility scoring.
  9. **Personalized Learning Roadmap:** Milestone timeline.

### 4. Learning Hub & Anti-Cheat Practice Quiz (2 Minutes)
- **Action:** Navigate to **Learning Hub** and open *"Introduction to Python Programming"*.
- **Action:** View structured curriculum and lesson markdown notes.
- **Action:** Start **Practice Quiz**, answer 3 multiple-choice questions, and submit.
- **Key Talking Points:** Explain that `correct_answer` is never sent to the client. Server evaluates the submission, records the attempt, calculates score, and awards deduplicated XP (+30 XP) via idempotent action keys.

### 5. Verifiable Certification & Digital Skill Passport (1.5 Minutes)
- **Action:** Open **Certificates Screen** to display earned certificate (`LSE-CERT-2026-00001-9E2A`).
- **Action:** Demonstrate **Public Verification** endpoint (`/certificates/verify/{id}`) confirming authenticity without authentication.
- **Action:** Open **Skill Passport** showing verified masteries, achievements, and chronological milestone history.

### 6. Hyperlocal Mentor Discovery & Escrow Booking (1.5 Minutes)
- **Action:** Open **Explore Screen**.
- **Action:** View nearby mentors computed via the Haversine distance formula.
- **Action:** Book a 1-on-1 session with a mentor.
- **Key Talking Points:** Explain the **Escrow Wallet System**: credits are deducted from learner and held securely in escrow until session completion.

### 7. Real-Time WebSocket Chat & Verified Reviews (1.5 Minutes)
- **Action:** Open **Chat Screen** and send a real-time message via WebSocket connection.
- **Action:** Mark session as completed to release escrow credits to mentor.
- **Action:** Submit 5-star review with comment, updating mentor's public rating.

### 8. Admin Moderation Portal & Conclusion (1 Minute)
- **Action:** Open **Admin Dashboard** (`/admin/stats` and `/admin/users`).
- **Action:** Show safety report moderation and system metrics.
- **Conclusion:** Summarize the full cycle: **LEARN ──► PRACTICE ──► CERTIFY ──► PASSPORT ──► AI MATCH ──► EXCHANGE ──► GROW.**
