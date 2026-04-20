from pydantic import BaseModel,Field
from typing import Annotated,Literal,Optional
from datetime import datetime

class Chats(BaseModel):
    user_id : str
    chat_id: str
    chat_title : str
    created_at : datetime
    
    
class ChatMessage(BaseModel):
    chat_id : str
    message : Annotated[str, Field(..., title='Enter your message')]


class Message(BaseModel):
    user_id: str
    chat_id: str
    message: str
    role: Literal["user", "assistant"]
    emotion: str | None = None
    crisis_detected: bool | None = None
    created_at: datetime

    
    
