import logging
from datetime import datetime
from bson import ObjectId
from database import db
from config import settings

logger = logging.getLogger(__name__)


def _col(name: str):
    if db.client is None:
        raise Exception("MongoDB not connected. Ensure connect_to_mongo() ran on startup.")
    return db.client[settings.DATABASE_NAME][name]



def _serialize_user(user: dict) -> dict | None:
    if not user:
        return None

    # Ensure all fields exist, provide sensible defaults if missing
    return {
        "id": str(user.get("_id")),
        "user_name": user.get("user_name") or "Unknown",
        "user_email": user.get("user_email") or "unknown@example.com",
        "user_gender": user.get("user_gender"),
        "user_dob": (
            user["user_dob"].isoformat()
            if isinstance(user.get("user_dob"), datetime)
            else str(user.get("user_dob")) if user.get("user_dob") else None
        ),
        "disabled": user.get("disabled", False),
        "created_at": (
            user["created_at"].isoformat()
            if isinstance(user.get("created_at"), datetime)
            else str(user.get("created_at")) if user.get("created_at") else None
        ),
        "updated_at": (
            user["updated_at"].isoformat()
            if isinstance(user.get("updated_at"), datetime)
            else str(user.get("updated_at")) if user.get("updated_at") else None
        ),
        "role": user.get("role", "user"),
    }



async def get_user_profile(user_id: str) -> dict | None:
    """
    Fetch a user by ID (UUID string stored as _id in MongoDB)
    """
    # Do NOT convert to ObjectId if using UUIDs
    user = await _col("users").find_one({"user_id": user_id})
    if not user:
        logger.warning("User not found: %s", user_id)
        return None
    logger.info("RAW USER: %s", user)
    return _serialize_user(user)




async def update_user_profile(user: dict, update_data: dict) -> dict | None:
    user_id = user.get("user_id") or user.get("id")
    if not user_id:
        return None
    update_data["updated_at"] = datetime.utcnow()
    await _col("users").update_one(
        {"_id": ObjectId(str(user_id))}, {"$set": update_data}
    )
    return await get_user_profile(str(user_id))



async def get_report(user_id: str) -> dict | None:
    report_doc = await _col("reports").find_one({"user_id": user_id})
    if report_doc:
        return {
            "report_text":  report_doc["report_text"],
            "generated_at": report_doc["generated_at"],
        }
    return await generate_report(user_id)



async def generate_report(user_id: str) -> dict | None:
    from utils.report_generator import summarize_chats, generate_final_report

    user = await get_user_profile(user_id)
    if not user:
        return None

    user_chats = await _col("chats").find({"user_id": user_id}).to_list(None)
    chat_texts: list[str] = []
    for chat in user_chats:
        messages_doc = await _col("chat_messages").find_one({"chat_id": chat["_id"]})
        if messages_doc:
            chat_texts.extend(
                m["message"] for m in messages_doc.get("messages", [])
                if m.get("role") == "user"
            )

    journals      = await _col("journal_entries").find({"user_id": user_id}).to_list(None)
    journal_texts = [j["content"] for j in journals]
    moods         = await _col("mood_entries").find({"user_id": user_id}).to_list(None)

    journal_summaries = await summarize_chats(journal_texts, chunk_size=5)
    chat_summaries    = await summarize_chats(chat_texts,    chunk_size=5)

    report_text = await generate_final_report(
        username=user["user_name"],
        chat_summaries=chat_summaries,
        journal_summaries=journal_summaries,
        moods=moods,
    )

    now = datetime.utcnow()
    await _col("reports").update_one(
        {"user_id": user_id},
        {"$set": {"report_text": report_text, "generated_at": now}},
        upsert=True,
    )
    return {"report_text": report_text, "generated_at": now}