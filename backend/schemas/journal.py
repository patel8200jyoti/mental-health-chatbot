from datetime import datetime


def journal_entity(journal , user_id,sentiment, mood,reflection):
    return{
        "user_id" : user_id,
        "content" : journal['content'],
        'sentiment_score' : sentiment,
        'mood_detected': str(mood),
        'ai_reflection' : str(reflection),
        'created_at': datetime.utcnow(),
    }
    

def journal_schema(journal):
    oid = str(journal['_id'])
    return {
        'id':             oid,
        'journal_id':     oid,  
        '_id':            oid,  
        'user_id':        journal['user_id'],
        'content':        journal['content'],
        'sentiment_score': journal.get('sentiment_score', 0),
        'mood_detected':  journal.get('mood_detected', ''),
        'ai_reflection':  journal.get('ai_reflection', ''),
        'created_at':     str(journal.get('created_at', '')),
    }
    
    