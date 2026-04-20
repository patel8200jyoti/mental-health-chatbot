from pydantic import BaseModel, Field, field_validator
from typing import Annotated, Optional
from datetime import datetime, date


class MoodCreate(BaseModel):
    user_mood: Annotated[
        str,
        Field(..., title='Mood', description='sad, okay, calm, happy or great')
    ]
    value: Annotated[Optional[int], Field(default=None, title='mood score')] = None
    mood_date: Annotated[Optional[date], Field(default=None, title='date')] = None


    @field_validator('user_mood', mode='before')
    @classmethod
    def normalise_mood(cls, v):
        if not isinstance(v, str):
            raise ValueError('user_mood must be a string')
        v = v.strip().lower()
        allowed = {'sad', 'okay', 'calm', 'happy', 'great'}
        if v not in allowed:
            raise ValueError(f"user_mood must be one of {allowed}, got '{v}'")
        return v


class MoodResponse(BaseModel):
    user_id:    str
    user_mood:  str
    mood_score: int
    mood_date:  date
    created_at: datetime