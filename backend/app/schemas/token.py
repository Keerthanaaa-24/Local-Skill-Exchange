from typing import Optional
from pydantic import BaseModel

class Token(BaseModel):
    access_token: str
    token_type: str
    is_guest: Optional[bool] = False

class TokenPayload(BaseModel):
    sub: str = None
