from pydantic import BaseModel

class SkillBase(BaseModel):
    id: int
    name: str
    category: str

    class Config:
        from_attributes = True
