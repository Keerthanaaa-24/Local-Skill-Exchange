from sqlalchemy import Column, Integer, String, Text, Float, Boolean, ForeignKey, DateTime, Table, JSON, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    name = Column(String(255), nullable=False)
    title = Column(String(255), default="Aspiring Creator")
    avatar_url = Column(String(255), default="https://i.pravatar.cc/150")
    rating = Column(Float, default=5.0)
    reviews = Column(Integer, default=0)
    xp = Column(Integer, default=0)
    credits = Column(Integer, default=100)
    streak_days = Column(Integer, default=0)
    is_online = Column(Boolean, default=False)
    is_admin = Column(Boolean, default=False)
    is_test_user = Column(Boolean, default=False, nullable=False, index=True)
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    skills_offered = relationship("UserSkillOffered", back_populates="user")
    skills_wanted = relationship("UserSkillWanted", back_populates="user")
    badges = relationship("UserBadge", back_populates="user")

class Skill(Base):
    __tablename__ = "skills"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, index=True)
    category = Column(String(100))

class UserSkillOffered(Base):
    __tablename__ = "user_skills_offered"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    skill_id = Column(Integer, ForeignKey("skills.id"), index=True)

    user = relationship("User", back_populates="skills_offered")
    skill = relationship("Skill")

class UserSkillWanted(Base):
    __tablename__ = "user_skills_wanted"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    skill_id = Column(Integer, ForeignKey("skills.id"), index=True)

    user = relationship("User", back_populates="skills_wanted")
    skill = relationship("Skill")

class UserBadge(Base):
    __tablename__ = "user_badges"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    badge_name = Column(String(100))

    user = relationship("User", back_populates="badges")

class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)
    mentee_id = Column(Integer, ForeignKey("users.id"), index=True)
    mentor_id = Column(Integer, ForeignKey("users.id"), index=True)
    skill_id = Column(Integer, ForeignKey("skills.id"), index=True)
    date = Column(DateTime, index=True)
    status = Column(String(50), default="upcoming", index=True) # upcoming, completed, canceled
    location = Column(String(255))
    credits_cost = Column(Integer, default=10)

    mentee = relationship("User", foreign_keys=[mentee_id])
    mentor = relationship("User", foreign_keys=[mentor_id])
    skill = relationship("Skill")

    @property
    def mentor_name(self) -> str:
        return self.mentor.name if self.mentor else "Mentor"

    @property
    def learner_name(self) -> str:
        return self.mentee.name if self.mentee else "Learner"

    @property
    def learner_id(self) -> int:
        return self.mentee_id

    @property
    def skill_title(self) -> str:
        return self.skill.name if self.skill else "Skill Session"

    @property
    def booking_date(self) -> str:
        return self.date.strftime("%Y-%m-%d") if self.date else ""

    @property
    def booking_time(self) -> str:
        return self.date.strftime("%H:%M") if self.date else ""

    @property
    def booking_status(self) -> str:
        return self.status

    @property
    def meeting_type(self) -> str:
        return self.location or "online"

    @property
    def credits(self) -> int:
        return self.credits_cost or 10

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    amount = Column(Integer) # positive for gain, negative for spent
    description = Column(String(255))
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), index=True)

    user = relationship("User")

class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"), index=True)
    receiver_id = Column(Integer, ForeignKey("users.id"), index=True)
    content = Column(String(1000))
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc), index=True)
    is_read = Column(Boolean, default=False, index=True)

    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])

class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True)
    reviewer_id = Column(Integer, ForeignKey("users.id"), index=True)
    reviewee_id = Column(Integer, ForeignKey("users.id"), index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), index=True)
    rating = Column(Float)
    comment = Column(String(500))
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), index=True)

    reviewer = relationship("User", foreign_keys=[reviewer_id])
    reviewee = relationship("User", foreign_keys=[reviewee_id])
    booking = relationship("Booking")

class LearningPath(Base):
    __tablename__ = "learning_paths"

    id = Column(Integer, primary_key=True, index=True)
    skill_id = Column(Integer, ForeignKey("skills.id"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    # optional estimated total minutes
    estimated_minutes = Column(Integer, nullable=True)

    skill = relationship("Skill")
    lessons = relationship("Lesson", back_populates="learning_path", cascade="all, delete-orphan")

class Lesson(Base):
    __tablename__ = "lessons"

    id = Column(Integer, primary_key=True, index=True)
    learning_path_id = Column(Integer, ForeignKey("learning_paths.id"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=True)  # plain text or markdown
    summary = Column(Text, nullable=True)
    video_url = Column(String(500), nullable=True)
    pdf_url = Column(String(500), nullable=True)
    doc_url = Column(String(500), nullable=True)
    order = Column(Integer, nullable=False)  # ordering of lessons
    estimated_minutes = Column(Integer, nullable=True)

    learning_path = relationship("LearningPath", back_populates="lessons")
    resources = relationship("LearningResource", back_populates="lesson", cascade="all, delete-orphan")

# Learning Resource model for verified study materials (YouTube, OER PDFs, Official Docs, PPTs)
class LearningResource(Base):
    __tablename__ = "learning_resources"

    id = Column(Integer, primary_key=True, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)
    resource_type = Column(String(50), default="DOCS", nullable=False)  # VIDEO, PDF, PPT, DOCS, ARTICLE
    title = Column(String(255), nullable=False)
    url = Column(String(500), nullable=False)
    source = Column(String(100), nullable=True)  # e.g., YouTube, Mozilla MDN, Python Docs, MIT OpenCourseWare
    duration_minutes = Column(Integer, nullable=True)
    is_primary = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    lesson = relationship("Lesson", back_populates="resources")

# Practice Question model for MCQ practice
class PracticeQuestion(Base):
    __tablename__ = "practice_questions"

    id = Column(Integer, primary_key=True, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)
    question = Column(Text, nullable=False)
    question_type = Column(String(50), default="mcq", nullable=False)
    options = Column(JSON, nullable=False)  # list of option strings
    correct_answer = Column(String(255), nullable=False)  # stored securely, not exposed
    explanation = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    lesson = relationship("Lesson", back_populates="practice_questions")

# Practice Attempt model – stores user attempts and scores
class PracticeAttempt(Base):
    __tablename__ = "practice_attempts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)
    score = Column(Integer, nullable=False)  # percentage score (0-100)
    total_questions = Column(Integer, nullable=False)
    correct_answers = Column(Integer, nullable=False)
    completed_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User")
    lesson = relationship("Lesson")

# Timed Quiz model for path or lesson assessments
class Quiz(Base):
    __tablename__ = "quizzes"

    id = Column(Integer, primary_key=True, index=True)
    learning_path_id = Column(Integer, ForeignKey("learning_paths.id", ondelete="CASCADE"), nullable=False, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    time_limit_minutes = Column(Integer, default=15, nullable=False)
    passing_percentage = Column(Integer, default=70, nullable=False)
    max_attempts = Column(Integer, default=10, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    learning_path = relationship("LearningPath", back_populates="quizzes")
    lesson = relationship("Lesson")
    questions = relationship("QuizQuestion", back_populates="quiz", cascade="all, delete-orphan")
    attempts = relationship("QuizAttempt", back_populates="quiz", cascade="all, delete-orphan")

# Timed Quiz Question model
class QuizQuestion(Base):
    __tablename__ = "quiz_questions"

    id = Column(Integer, primary_key=True, index=True)
    quiz_id = Column(Integer, ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False, index=True)
    question_text = Column(Text, nullable=False)
    question_type = Column(String(50), default="mcq", nullable=False)  # mcq, true_false, scenario
    options = Column(JSON, nullable=False)  # list of option strings
    correct_answer = Column(String(255), nullable=False)  # stored securely
    explanation = Column(Text, nullable=True)
    points = Column(Integer, default=10, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    quiz = relationship("Quiz", back_populates="questions")

# Timed Quiz Attempt model
class QuizAttempt(Base):
    __tablename__ = "quiz_attempts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    quiz_id = Column(Integer, ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False, index=True)
    attempt_number = Column(Integer, default=1, nullable=False)
    marks_obtained = Column(Integer, default=0, nullable=False)
    maximum_marks = Column(Integer, default=0, nullable=False)
    percentage = Column(Float, default=0.0, nullable=False)
    passed = Column(Boolean, default=False, nullable=False)
    duration_seconds = Column(Integer, default=0, nullable=False)
    answers_data = Column(JSON, nullable=True)  # user submissions
    completed_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User")
    quiz = relationship("Quiz", back_populates="attempts")

# Extend Lesson & LearningPath relationships
Lesson.practice_questions = relationship("PracticeQuestion", back_populates="lesson", cascade="all, delete-orphan")
LearningPath.quizzes = relationship("Quiz", back_populates="learning_path", cascade="all, delete-orphan")

# Notification model for user notifications
class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=True)
    type = Column(String(50), default="general", nullable=True)
    target_id = Column(Integer, nullable=True)
    is_read = Column(Boolean, default=False, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), index=True)

    user = relationship("User")

class UserLearningProgress(Base):
    __tablename__ = "user_learning_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    learning_path_id = Column(Integer, ForeignKey("learning_paths.id"), nullable=False, index=True)
    started_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    completed_at = Column(DateTime, nullable=True)
    completed_lessons = Column(String(255), default="")

    user = relationship("User")
    learning_path = relationship("LearningPath")

class Certificate(Base):
    __tablename__ = "certificates"

    id = Column(Integer, primary_key=True, index=True)
    certificate_number = Column(String(100), unique=True, index=True, nullable=False)
    verification_code = Column(String(64), unique=True, index=True, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    learning_path_id = Column(Integer, ForeignKey("learning_paths.id", ondelete="CASCADE"), nullable=False, index=True)
    skill_id = Column(Integer, ForeignKey("skills.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    issued_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    completed_at = Column(DateTime, nullable=False)
    status = Column(String(50), default="valid", nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    __table_args__ = (
        UniqueConstraint("user_id", "learning_path_id", name="uq_user_learning_path_certificate"),
    )

    user = relationship("User")
    learning_path = relationship("LearningPath")
    skill = relationship("Skill")

class UserReport(Base):
    __tablename__ = "user_reports"

    id = Column(Integer, primary_key=True, index=True)
    reporter_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    reported_user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    reason = Column(String(100), nullable=False)  # e.g., harassment, spam, inappropriate_content, scam, other
    description = Column(Text, nullable=True)
    status = Column(String(50), default="pending", nullable=False)  # pending, reviewed, resolved, dismissed
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    reporter = relationship("User", foreign_keys=[reporter_id])
    reported_user = relationship("User", foreign_keys=[reported_user_id])

class UserBlock(Base):
    __tablename__ = "user_blocks"

    id = Column(Integer, primary_key=True, index=True)
    blocker_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    blocked_user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    __table_args__ = (
        UniqueConstraint("blocker_id", "blocked_user_id", name="uq_blocker_blocked"),
    )

    blocker = relationship("User", foreign_keys=[blocker_id])
    blocked_user = relationship("User", foreign_keys=[blocked_user_id])

class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(50), unique=True, index=True, nullable=False)
    title = Column(String(100), nullable=False)
    description = Column(String(255), nullable=False)
    requirement = Column(String(255), nullable=False)
    icon = Column(String(50), default="emoji_events")
    category = Column(String(50), default="learning")

class UserAchievement(Base):
    __tablename__ = "user_achievements"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    achievement_id = Column(Integer, ForeignKey("achievements.id", ondelete="CASCADE"), nullable=False, index=True)
    earned_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    __table_args__ = (
        UniqueConstraint("user_id", "achievement_id", name="uq_user_achievement"),
    )

    user = relationship("User")
    achievement = relationship("Achievement")

class UserXpLog(Base):
    __tablename__ = "user_xp_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    action_key = Column(String(100), nullable=False, index=True)
    xp_amount = Column(Integer, nullable=False)
    description = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    __table_args__ = (
        UniqueConstraint("user_id", "action_key", name="uq_user_xp_action"),
    )

    user = relationship("User")




