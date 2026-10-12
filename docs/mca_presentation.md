# MCA Final Project Presentation — Local Skill Exchange

## Slide 1: Title Slide
- **Project Title:** Local Skill Exchange: A Hyperlocal, Gamified & AI-Driven Skill Swapping & Peer Learning Platform
- **Degree / Department:** Master of Computer Applications (MCA) — Capstone Project
- **Domain:** Web & Mobile Full-Stack Engineering, Peer-to-Peer EdTech, Explainable Artificial Intelligence
- **Technology Stack:** Flutter (Dart), FastAPI (Python 3.12+), SQLAlchemy ORM, MySQL 8.0, WebSockets, Google Maps API

---

## Slide 2: Project Overview & Core Philosophy
- **Overview:** A zero-cost community skill-sharing ecosystem where users learn, exchange expertise, earn verified credentials, and track progress using an embedded Personal AI Skill Growth Engine.
- **The 7-Pillar Pipeline:**
  $$\text{LEARN} \longrightarrow \text{PRACTICE} \longrightarrow \text{CERTIFY} \longrightarrow \text{PASSPORT} \longrightarrow \text{AI MATCH} \longrightarrow \text{EXCHANGE} \longrightarrow \text{GROW}$$

---

## Slide 3: Problem Statement
- **Prohibitive Costs:** Commercial online learning platforms and 1-on-1 tutoring have high subscription barriers.
- **Lack of Local Engagement:** Disconnect between learners living in the same vicinity who possess complementary skills.
- **Informal Credentialing Gap:** Traditional informal exchanges lack verifiable proof of mastery.
- **Drop-off & Inaction:** Absence of adaptive guidance leaves learners unmotivated without clear daily goals.

---

## Slide 4: Existing Systems vs. Proposed System

| Parameter | Traditional MOOCs (Udemy / Coursera) | Tutoring Platforms (Wyzant) | **Proposed Local Skill Exchange** |
|---|---|---|---|
| **Cost Model** | Paid subscriptions / course fees | Hourly monetary billing | **Zero monetary cost; credit barter escrow** |
| **Interaction** | Passive asynchronous videos | Paid commercial 1-on-1 | **Hyperlocal peer-to-peer exchange + Live Chat** |
| **Verification** | Simple unverified completion PDF | No standard certification | **Cryptographic certificates & Public Skill Passport** |
| **AI Personalization** | Generic search filters | Basic keyword matching | **Deterministic AI Skill Growth Engine & Adaptive Roadmap** |
| **Engagement** | Low completion rates (<15%) | Transactional only | **Gamified XP, Levels, Streaks & Privacy Leaderboard** |

---

## Slide 5: System Architecture & Tech Stack
```
┌─────────────────────────────────────────────────────────────┐
│               PRESENTATION TIER (FLUTTER)                   │
│   Flutter Web & Mobile (Android)  •  Riverpod State Mgmt    │
│   Dio HTTP Client (Auth Interceptor) • WebSocket Real-Time  │
└──────────────────────────────┬──────────────────────────────┘
                               │ REST / JSON & WebSockets
┌──────────────────────────────▼──────────────────────────────┐
│              APPLICATION TIER (FASTAPI / PYTHON)            │
│   Uvicorn ASGI  •  Pydantic V2 Schemas  •  JWT Auth (Bcrypt)│
│   AI Skill Growth Engine  •  Gamification Engine  •  Escrow  │
└──────────────────────────────┬──────────────────────────────┘
                               │ SQLAlchemy ORM (Connection Pool)
┌──────────────────────────────▼──────────────────────────────┐
│                    DATABASE TIER (MYSQL)                    │
│   21 Relational Tables  •  Foreign Keys & Unique Indexes    │
│   Transaction ACID Integrity  •  Audit Logs                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Slide 6: Key Functional Modules

1. **Interactive Learning Hub:** Structured curricula, lesson progress tracking, and server-evaluated quizzes with privacy-safe answer obfuscation.
2. **Personal AI Skill Growth Engine:** 
   - Historical vs current quiz accuracy tracking & growth velocity.
   - Adaptive next-step recommendations (Continue, Review, Practice, Next Goal).
   - Dynamic daily objectives with XP incentives.
   - Two-way reciprocal exchange matching ($\text{User A teaches X/wants Y} \leftrightarrow \text{User B teaches Y/wants X}$).
3. **Credit-Based Escrow Wallet:** Automated credit hold upon booking creation; released to mentor upon session completion; refunded on cancellation.
4. **Verifiable Certification & Skill Passport:** Unique certificate IDs with public cryptographic verification endpoints.
5. **Real-Time WebSocket Chat:** Low-latency 1-on-1 messaging with live presence indicators.
6. **Gamification & Community Trust:** Deduplicated XP awards, 5-tier leveling, streak preservation, bilateral safety moderation, and privacy-safe public leaderboards.

---

## Slide 7: Mathematical & Algorithmic Foundations

### 1. Haversine Distance Formula (Hyperlocal Proximity)
$$d = 2R \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta \phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta \lambda}{2}\right)}\right)$$
- $R = 6371\text{ km}$ (Earth radius).

### 2. Multi-Factor AI Mentor Compatibility Matching ($S \in [0, 100]$)
$$S = 0.40 \cdot S_{\text{skill}} + 0.25 \cdot S_{\text{reciprocal}} + 0.15 \cdot S_{\text{rating}} + 0.10 \cdot S_{\text{experience}} + 0.10 \cdot S_{\text{proximity}}$$

### 3. Composite Mastery Index Calculation
$$\text{Mastery Index} = \min\left(100, \min(40, N_{\text{certs}} \cdot 40) + \min\left(30, \frac{\text{Accuracy}_{\text{avg}}}{100} \cdot 30\right) + \min(30, N_{\text{paths}} \cdot 20 + N_{\text{skills}} \cdot 10)\right)$$

---

## Slide 8: Security, Privacy & Integrity Measures
- **Authentication:** Bcrypt password hashing + stateless signed JWT Bearer tokens.
- **Role-Based Access Control (RBAC):** Admin endpoints protected with `@admin_required`.
- **Data Privacy & Redaction:** Public user profiles redact emails, passwords, and credit balances.
- **XP Idempotency:** Action-key uniqueness prevents XP farming or duplicate balance inflation.
- **Anti-Cheat Quizzes:** Quiz correct answers are stripped before sending to the client and evaluated strictly on the backend.

---

## Slide 9: Verification & Quality Assurance Results

| Test Suite | Total Tests | Passed | Success Rate |
|---|---|---|---|
| **Full Backend Regression Suite (Phases D–K)** | 68 | 68 | **100%** |
| **Phase O Advanced AI Intelligence Suite** | 12 | 12 | **100%** |
| **Phase P Production Excellence & Security Suite** | 16 | 16 | **100%** |
| **Total Automated Test Assertions** | **96** | **96** | **100%** |
| **Flutter Static Analysis (`flutter analyze`)** | — | **0 Errors, 0 Warnings** | **100%** |

---

## Slide 10: Live Demonstration Workflow
1. **Student Journey:** Sign in $\rightarrow$ Browse Learning Hub $\rightarrow$ Take Quiz $\rightarrow$ Earn Certificate.
2. **AI Skill Coach:** View Mastery Index ($79/100$) $\rightarrow$ Read personalized growth narrative $\rightarrow$ Complete Daily Goal.
3. **Hyperlocal Exchange:** Discover nearby Python mentor (Haversine distance) $\rightarrow$ Book 1-on-1 session (Escrow hold) $\rightarrow$ Chat via WebSocket $\rightarrow$ Complete session & leave verified review.
4. **Passport & Leaderboard:** Check updated Skill Passport & Gamification Leaderboard rank.

---

## Slide 11: Limitations & Future Enhancements
- **Current Limitations:** Video calls currently open via external meeting links; Web push notifications depend on active browser session.
- **Future Enhancements:**
  - Integrated WebRTC peer-to-peer in-app video calling.
  - Native Push Notifications via Firebase Cloud Messaging (FCM).
  - Fine-tuned local LLM for conversational practice quiz explanations.

---

## Slide 12: Conclusion & Viva Q&A
- **Summary:** *Local Skill Exchange* successfully delivers a robust, production-ready, full-stack MCA Capstone platform integrating verified education, peer economy, and deterministic AI intelligence.
- **Open for Questions:** Thank you to the respected evaluators and examiners!
