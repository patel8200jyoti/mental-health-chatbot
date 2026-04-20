from datetime import datetime
from uuid import uuid4

def chat_entity(chat) -> dict:
    """
    Prepare a new chat document for MongoDB.
    """
    return {
        'chat_id': chat['chat_id'],
        'user_id': chat['user_id'],         
        'title': chat.get('title', 'New Chat'),
        'created_at': datetime.utcnow(),
        'updated_at': datetime.utcnow(),
        
    }

def chat_schema(chat) -> dict:
    """
    Convert a MongoDB chat document to JSON-serializable format.
    """
    return {
        'chat_id': str(chat['chat_id']),
        'user_id': str(chat['user_id']),
        'title': chat.get('title'),
        'created_at': chat.get('created_at'),
        
    }