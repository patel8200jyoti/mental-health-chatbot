from config import settings
from database import get_database
from utils.emotion_detector import analyse_chats
from langchain_core.messages import HumanMessage,AIMessage
from datetime import datetime
from models.chat import Message

import logging
logger = logging.getLogger(__name__)

class MemoryHistory:
    
    def __init__(self,chat_id:str):
        
        self.chat_id = chat_id
        
    async def load_message(self, user_id: str, limit: int = 50):
        db = await get_database()

        cursor = db.chat_messages.find(
            {
                "chat_id": self.chat_id,
                "user_id": user_id
            }
        ).sort("created_at", 1).limit(limit)

        msgs = await cursor.to_list(length=limit)
        logger.info(f"Loaded {len(msgs)} messages")

        result = []
        for msg in msgs:
            if msg["role"] == "user":
                result.append(HumanMessage(content=msg["message"]))  
            else:
                result.append(AIMessage(content=msg["message"])) 
        return result
    
    
    async def save_message(self,user_id : str,message : str, role : str,crisis_detected: bool = None):
        db = await get_database()
        emotion= await analyse_chats(message) if role=='user' else None
        msg = Message(
            user_id=user_id,
            chat_id=self.chat_id,
            message=message,
            role=role,
            emotion= emotion,
            crisis_detected=crisis_detected,
            created_at=datetime.utcnow()
        )

        await db.chat_messages.insert_one(msg.model_dump())
        logger.info('Message added')
        
        
    async def clear(self):
        db = await get_database()
        await db.chat_messages.delete_many({'chat_id':self.chat_id})
        logger.info("Chat cleared")