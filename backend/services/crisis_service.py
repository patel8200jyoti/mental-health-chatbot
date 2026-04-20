from database import get_database
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

# Helplines — you can expand this or make it region-aware later
HELPLINES = [
    {"name": "iCall (India)", "number": "9152987821", "available": "Mon–Sat, 8am–10pm"},
    {"name": "Vandrevala Foundation", "number": "1860-2662-345", "available": "24/7"},
    {"name": "AASRA", "number": "9820466627", "available": "24/7"},
    {"name": "Crisis Text Line (Global)", "number": "Text HOME to 741741", "available": "24/7"},
]

CRISIS_MESSAGE = (
    "\n\n---\n"
    "💙 I'm really concerned about your safety right now. "
    "Please know you're not alone — reaching out to someone who can help is important.\n\n"
    "**Emergency Support Resources:**\n"
)



async def save_crisis_alert(user_id: str, chat_id: str, message: str, detection_method: str):
    """Persist the crisis event to MongoDB."""
    
    db = await get_database()
    alert = {
        "user_id": user_id,
        "chat_id": chat_id,
        "message": message,
        "detection_method": detection_method,
        "resolved": False,
        "created_at": datetime.utcnow(),
    }
    result = await db.crisis_alerts.insert_one(alert)
    logger.warning(f"Crisis alert saved for user {user_id} | method: {detection_method}")
    return str(result.inserted_id)




def build_crisis_response(bot_response: str) -> str:
    """Appends helpline info to the bot's normal response."""
    
    helpline_text = CRISIS_MESSAGE
    for h in HELPLINES:
        helpline_text += f"• **{h['name']}**: {h['number']} ({h['available']})\n"
    helpline_text += "\nIf you're in immediate danger, please call your local emergency services (112 in India)."
    return bot_response + helpline_text