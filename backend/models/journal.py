from pydantic import BaseModel,Field
from typing import Annotated,Optional
from datetime import datetime

class JournalCreate(BaseModel):
    content : Annotated[Optional[str],Field(title='enter your journal entries')]
    
    
class JournalResponse(BaseModel):
    user_id : str
    journal_id:     str
    id: str
    content : str
    sentiment_score : float
    ai_reflection : str
    mood_detected : str
    created_at : datetime
    