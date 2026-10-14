from fastapi import FastAPI, Response, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
import os
from .core.config import settings
from .api.routes import auth, users, skills, bookings, chat, reviews, notifications, recommendations, admin, learning, certificates, passport, community, safety, gamification, wallet
from .db.database import engine, Base, SessionLocal


import time

# Create tables with automatic retry to handle cloud database cold starts
def _init_db_with_retry(max_attempts: int = 5, delay: int = 2):
    for attempt in range(1, max_attempts + 1):
        try:
            Base.metadata.create_all(bind=engine)
            return
        except Exception as e:
            if attempt == max_attempts:
                print(f"[Warning] Base.metadata.create_all deferred: {e}")
            else:
                print(f"[Startup] Waiting for database (attempt {attempt}/{max_attempts})...")
                time.sleep(delay)

_init_db_with_retry()


# Ensure uploads directory exists
UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "uploads")
os.makedirs(os.path.join(UPLOAD_DIR, "avatars"), exist_ok=True)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Mount static uploads directory for profile photos & media
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# Configure CORS middleware
cors_origins_raw = getattr(settings, "CORS_ORIGINS", "*")
cors_origins = [o.strip() for o in cors_origins_raw.split(",") if o.strip()]

if "*" in cors_origins or not cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=".*",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    # Explicit production origins + localhost development fallback
    dev_origins = ["http://localhost", "http://127.0.0.1"]
    combined_origins = list(set(cors_origins + dev_origins))
    app.add_middleware(
        CORSMiddleware,
        allow_origins=combined_origins,
        allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )


app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])
app.include_router(users.router, prefix=f"{settings.API_V1_STR}/users", tags=["users"])
app.include_router(skills.router, prefix=f"{settings.API_V1_STR}/skills", tags=["skills"])
app.include_router(bookings.router, prefix=f"{settings.API_V1_STR}/bookings", tags=["bookings"])
app.include_router(chat.router, prefix=f"{settings.API_V1_STR}/chat", tags=["chat"])
app.include_router(chat.router, prefix=f"{settings.API_V1_STR}/chats", tags=["chats"])
app.include_router(chat.router, prefix=f"{settings.API_V1_STR}/messages", tags=["messages"])
app.include_router(reviews.router, prefix=f"{settings.API_V1_STR}/reviews", tags=["reviews"])
app.include_router(notifications.router, prefix=f"{settings.API_V1_STR}/notifications", tags=["notifications"])
app.include_router(recommendations.router, prefix=f"{settings.API_V1_STR}/recommendations", tags=["recommendations"])
app.include_router(learning.router, prefix=f"{settings.API_V1_STR}/learning", tags=["learning"])  # new learning endpoints
app.include_router(certificates.router, prefix=f"{settings.API_V1_STR}/certificates", tags=["certificates"])
app.include_router(passport.router, prefix=f"{settings.API_V1_STR}/passport", tags=["passport"])
app.include_router(community.router, prefix=f"{settings.API_V1_STR}/community", tags=["community"])
app.include_router(safety.router, prefix=f"{settings.API_V1_STR}/safety", tags=["safety"])
app.include_router(admin.router, prefix=f"{settings.API_V1_STR}/admin", tags=["admin"])
app.include_router(gamification.router, prefix=f"{settings.API_V1_STR}/gamification", tags=["gamification"])
app.include_router(wallet.router, prefix=f"{settings.API_V1_STR}/wallet", tags=["wallet"])

@app.get("/")
def root():
    return {"message": "Welcome to Local Skill Exchange API"}

@app.get("/health", tags=["system"])
@app.get(f"{settings.API_V1_STR}/health", tags=["system"])
def health_check(response: Response):
    """
    Lightweight health check probe for platform monitoring.
    Distinguishes service availability from database connectivity.
    """
    db_status = "connected"
    is_healthy = True
    db = None
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
    except Exception as ex:
        db_status = f"disconnected: {ex.__class__.__name__}"
        is_healthy = False
    finally:
        if db:
            db.close()

    if not is_healthy:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {
            "status": "unhealthy",
            "api": "ok",
            "database": db_status,
            "version": settings.VERSION,
        }

    return {
        "status": "healthy",
        "api": "ok",
        "database": db_status,
        "version": settings.VERSION,
    }

