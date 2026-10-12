# Setup & Installation Guide — Local Skill Exchange

This guide outlines how to set up, configure, and run the **Local Skill Exchange** project from scratch on a clean machine.

---

## 1. System Prerequisites

Before starting, ensure the following software is installed:

- **Python:** Version 3.11 or higher (Python 3.14 verified)
- **Flutter SDK:** Version 3.29.0 or higher
- **MySQL Server:** Version 8.0 or higher (Running locally on port `3306`)
- **Git:** Version 2.40 or higher
- **Web Browser:** Google Chrome (for Flutter Web development & testing)

---

## 2. MySQL Database Setup

1. Open your MySQL client (Command Line, Workbench, or DBeaver).
2. Create the database:
   ```sql
   CREATE DATABASE local_skill_exchange CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```
3. Verify your local MySQL username and password (e.g., `root` / `YOUR_PASSWORD`).

---

## 3. Backend Setup (FastAPI)

1. Open a terminal in the project root directory:
   ```bash
   cd c:\Users\keert\OneDrive\Documents\Local_Skill_Exchange
   ```

2. (Optional) Create and activate a Python virtual environment:
   ```bash
   python -m venv .venv
   # Windows PowerShell
   .\.venv\Scripts\Activate.ps1
   # Linux / macOS
   source .venv/bin/activate
   ```

3. Configure Environment Variables:
   - Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
   - Update `.env` with your MySQL credentials:
     ```env
     DATABASE_URL=mysql+pymysql://root:YOUR_MYSQL_PASSWORD@localhost:3306/local_skill_exchange
     SECRET_KEY=super-secret-jwt-key
     ```

4. Install Python Dependencies:
   ```bash
   pip install fastapi uvicorn sqlalchemy pymysql pydantic pydantic-settings pyjwt passlib[bcrypt] python-dotenv
   ```

5. (Optional) Seed Initial Data:
   ```bash
   python scratch/ensure_skill.py
   python scratch/create_gamification_tables.py
   ```

6. Launch the FastAPI Server:
   ```bash
   python -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 --reload
   ```
   - Server running at: `http://127.0.0.1:8000`
   - Interactive OpenAPI docs: `http://127.0.0.1:8000/docs`

---

## 4. Frontend Setup (Flutter)

1. Open a second terminal window in the project root directory.

2. Fetch Flutter Packages:
   ```bash
   flutter pub get
   ```

3. Run Static Analysis:
   ```bash
   flutter analyze
   ```

4. Launch Flutter Application:
   - **Run on Chrome (Web):**
     ```bash
     flutter run -d chrome
     ```
   - **Run on Connected Mobile Device / Emulator:**
     ```bash
     flutter run
     ```

5. Build Release Production Bundle for Web:
   ```bash
   flutter build web
   ```
   - Compiled web output directory: `build/web`

---

## 5. Verification Commands

To run automated regression and production smoke tests:

```bash
# Run Full System Regression Test (Phases A through K)
python scratch/test_full_regression.py

# Run 25-Step Production Smoke Test
python scratch/smoke_test_production.py
```
