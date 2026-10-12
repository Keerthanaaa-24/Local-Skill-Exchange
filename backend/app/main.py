from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from .core.config import settings
from .api.routes import auth, users, skills, bookings, chat, reviews, notifications, recommendations, admin, learning, certificates, passport, community, safety, gamification, wallet
from .db.database import engine, Base

# Create tables for SQLite development. 
# For production MySQL, use Alembic migrations.
Base.metadata.create_all(bind=engine)

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

# Set all CORS enabled origins
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=".*",
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
