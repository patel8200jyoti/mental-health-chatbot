from database import get_database
from schemas.journal import journal_entity,journal_schema
from utils.emotion_detector import analyse_journal
from fastapi import HTTPException
from bson import ObjectId
import logging 
logger = logging.getLogger(__name__)


# Create Journal Entry 
async def create_journal(journal,user):
    db = await get_database()
    
    analysis = await analyse_journal(journal.content)
    logger.info(f"Journal analysis : {analysis}")
    
    journal_doc = journal_entity(
        journal=journal.model_dump(),
        user_id=user['user_id'],
        sentiment=analysis['sentiment_score'],
        mood=analysis['mood_detected'],
        reflection=analysis['reflection']
    )
    
    result = await db.journals.insert_one(journal_doc)
    created = await db.journals.find_one({"_id": result.inserted_id})
    logger.info(f"Journal entry created with id : {result.inserted_id}")
    return journal_schema(created)


# Fetch Journals
async def fetch_journal(user):
    db = await get_database()
    
    journal = db.journals.find({'user_id':user['user_id']},sort=[('created_at',-1)])
    
    journals = await journal.to_list(length=50)
    logger.info("Fetched journals for the user")
    
    return [journal_schema(j) for j in journals]




async def update_journal(journal_id, journal, user):
    db = await get_database()
    try:
        oid = ObjectId(journal_id)
    except Exception:
        raise HTTPException(400, "Invalid journal id")

    analysis = await analyse_journal(journal.content)
    journal_doc = journal_entity(
        journal=journal.model_dump(),
        user_id=user['user_id'],
        sentiment=analysis['sentiment_score'],
        mood=analysis['mood_detected'],
        reflection=analysis['reflection']
    )
    # Remove created_at so we don't overwrite the original timestamp
    journal_doc.pop('created_at', None)

    result = await db.journals.update_one(
        {"_id": oid, "user_id": user['user_id']},
        {"$set": journal_doc}
    )
    if result.matched_count == 0:
        raise HTTPException(404, "Journal not found")

    updated = await db.journals.find_one({"_id": oid})
    return journal_schema(updated)




async def delete_journal(journal_id, user):
    db = await get_database()
    try:
        oid = ObjectId(journal_id)
    except Exception:
        raise HTTPException(400, "Invalid journal id")

    result = await db.journals.delete_one(
        {"_id": oid, "user_id": user['user_id']}
    )
    if result.deleted_count == 0:
        raise HTTPException(404, "Journal not found")

    return {"message": "Journal deleted"}