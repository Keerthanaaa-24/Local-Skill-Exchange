from pydantic import BaseModel, field_validator
from typing import List, Optional, Any
from datetime import datetime

class LearningResourceOut(BaseModel):
    id: int
    lesson_id: int
    resource_type: str = "DOCS"
    title: str
    url: str
    source: Optional[str] = None
    duration_minutes: Optional[int] = None
    is_primary: bool = False

    class Config:
        from_attributes = True

class LessonOut(BaseModel):
    id: int
    learning_path_id: int
    title: str
    content: Optional[str] = None
    summary: Optional[str] = None
    video_url: Optional[str] = None
    pdf_url: Optional[str] = None
    doc_url: Optional[str] = None
    order: int
    estimated_minutes: Optional[int] = None
    resources: List[LearningResourceOut] = []

    class Config:
        from_attributes = True

class LearningPathOut(BaseModel):
    id: int
    skill_id: int
    title: str
    description: Optional[str] = None
    estimated_minutes: Optional[int] = None
    lessons: List[LessonOut] = []

    class Config:
        from_attributes = True

class UserLearningProgressOut(BaseModel):
    id: int
    user_id: int
    learning_path_id: int
    started_at: datetime
    completed_at: Optional[datetime] = None
    completed_lessons: List[int] = []

    @field_validator("completed_lessons", mode="before")
    @classmethod
    def parse_completed_lessons(cls, v):
        if isinstance(v, str):
            return [int(i) for i in v.split(",") if i.strip()]
        if isinstance(v, list):
            return [int(i) for i in v]
        return []

    class Config:
        from_attributes = True

class StartLearningResponse(BaseModel):
    progress: UserLearningProgressOut
    message: str = "Learning started"

class LessonCompleteResponse(BaseModel):
    progress: UserLearningProgressOut
    message: str = "Lesson marked complete"

class PracticeQuestionOut(BaseModel):
    id: int
    lesson_id: int
    question: str
    question_type: str = "mcq"
    options: List[str]
    explanation: Optional[str] = None

    @field_validator("options", mode="before")
    @classmethod
    def parse_options(cls, v):
        if isinstance(v, str):
            try:
                import json
                return json.loads(v)
            except Exception:
                return [v]
        return v or []

class PracticeAnswer(BaseModel):
    question_id: Any
    answer: str

class PracticeSubmission(BaseModel):
    answers: List[PracticeAnswer]

class PracticeResultOut(BaseModel):
    lesson_id: int
    total_questions: int
    correct_answers: int
    incorrect_answers: int
    percentage: float
    passed: bool
    feedback: List[dict]  # each dict: {"question_id": int, "correct": bool, "explanation": Optional[str]}

    class Config:
        from_attributes = True

class QuizQuestionOut(BaseModel):
    id: int
    quiz_id: int
    question_text: str
    question_type: str = "mcq"
    options: List[str]
    points: int = 10

    class Config:
        from_attributes = True

class QuizOut(BaseModel):
    id: int
    learning_path_id: int
    lesson_id: Optional[int] = None
    title: str
    description: Optional[str] = None
    time_limit_minutes: int = 15
    passing_percentage: int = 70
    max_attempts: int = 10
    questions: List[QuizQuestionOut] = []

    class Config:
        from_attributes = True

class QuizSubmissionItem(BaseModel):
    question_id: int
    answer: str

class QuizSubmission(BaseModel):
    answers: List[QuizSubmissionItem]
    duration_seconds: int = 0

class QuizFeedbackItem(BaseModel):
    question_id: int
    question_text: str
    user_answer: str
    correct_answer: str
    is_correct: bool
    explanation: Optional[str] = None
    points_earned: int
    points_possible: int

class QuizResultOut(BaseModel):
    quiz_id: int
    attempt_number: int
    marks_obtained: int
    maximum_marks: int
    percentage: float
    passed: bool
    xp_earned: int = 0
    feedback: List[QuizFeedbackItem] = []
    completed_at: datetime

class QuizAttemptOut(BaseModel):
    id: int
    user_id: int
    quiz_id: int
    attempt_number: int
    marks_obtained: int
    maximum_marks: int
    percentage: float
    passed: bool
    duration_seconds: int
    completed_at: datetime

    class Config:
        from_attributes = True

class LearningDashboardSkill(BaseModel):
    skill_id: int
    skill_name: str
    learning_path_id: int
    path_title: str
    total_lessons: int
    completed_lessons_count: int
    progress_percentage: float
    next_lesson_id: Optional[int] = None
    next_lesson_title: Optional[str] = None

class LearningDashboardOut(BaseModel):
    active_skills: List[LearningDashboardSkill] = []
    total_enrolled_paths: int = 0
    total_completed_paths: int = 0
    total_lessons_completed: int = 0
    overall_progress_percentage: float = 0.0
    quiz_average_score: float = 0.0
    total_quiz_attempts: int = 0
    total_certificates: int = 0
    streak_days: int = 0
    total_xp: int = 0
    recent_quiz_attempts: List[QuizAttemptOut] = []
