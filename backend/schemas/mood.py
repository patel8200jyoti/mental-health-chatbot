from datetime import datetime,date

MOOD_SCORE ={
    'sad': 2,
    'okay': 3,
    'calm': 4,
    'happy': 5,
    'great' : 6
}

def to_datetime(d: date | datetime) -> datetime:
    if isinstance(d, datetime):
        return d
    if isinstance(d, date):
        return datetime(d.year, d.month, d.day)
    raise ValueError("Invalid date type")

def mood_entity(mood, user_id) -> dict:
    mood_date = mood.get('mood_date') or date.today()
    mood_score = mood.get('value') or MOOD_SCORE.get(mood['user_mood'], 4)  # default 4

    return {
        "user_id": user_id,
        "user_mood": mood["user_mood"].lower(),
        "mood_score": int(mood_score),
        "mood_date": to_datetime(mood_date),
        "created_at": datetime.utcnow()
    }
    
    

def mood_schema(mood)->dict :
    
    return {
        "user_id": str(mood['user_id']),
        'user_mood': mood['user_mood'],
        'mood_score' : mood['mood_score'],
        'mood_date' : mood['mood_date'],
        'created_at' : mood['created_at']
    }