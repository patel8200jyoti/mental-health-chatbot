from database import get_database
from datetime import datetime, timedelta
from bson import ObjectId
import logging

logger = logging.getLogger(__name__)

# Maps the string mood label → numeric value (same as Flutter's moodValues)
MOOD_VALUES = {
    "sad":   1,
    "okay":  2,
    "calm":  3,
    "happy": 4,
    "great": 5,
}


# ── Stats ─────────────────────────────────────────────────────────────────────

async def get_system_stats():
    db = await get_database()

    total_users          = await db.users.count_documents({"role": "user"})
    total_professionals  = await db.users.count_documents({"role": "professional"})
    pending_approvals    = await db.users.count_documents(
        {"role": "professional", "is_approved": False, "is_active": True}
    )
    total_chats          = await db.chats.count_documents({})
    total_messages       = await db.chat_messages.count_documents({})
    total_moods          = await db.moods.count_documents({})
    total_journals       = await db.journals.count_documents({})
    total_crisis_alerts  = await db.crisis_alerts.count_documents({})
    unresolved_crisis    = await db.crisis_alerts.count_documents({"resolved": False})
    mood_streak_count    = await db.users.count_documents(
        {"role": "user", "mood_streak": {"$gte": 1}}
    )

    return {
        "total_users":              total_users,
        "total_professionals":      total_professionals,
        "pending_approvals":        pending_approvals,
        "total_chats":              total_chats,
        "total_messages":           total_messages,
        "total_moods_logged":       total_moods,
        "total_journals":           total_journals,
        "total_crisis_alerts":      total_crisis_alerts,
        "unresolved_crisis_alerts": unresolved_crisis,
        "mood_streak_count":        mood_streak_count,
        "generated_at":             datetime.utcnow(),
    }


async def get_dashboard_metrics():
    """
    Lightweight metrics for the 4 bottom stat cards.
    Keys MUST stay snake_case to match Flutter's stats["active_streak_count"] etc.
    """
    db = await get_database()

    active_streak_count = await db.users.count_documents(
        {"role": "user", "mood_streak": {"$gte": 1}}
    )
    total_journals = await db.journals.count_documents({})
    active_chats   = await db.chats.count_documents({})
    total_messages = await db.chat_messages.count_documents({})

    return {
        "active_streak_count": active_streak_count,
        "total_journals":      total_journals,
        "active_chats":        active_chats,
        "total_messages":      total_messages,
        "generated_at":        datetime.utcnow(),
    }


async def get_mood_trends(range_key: str = "M"):
    """
    Returns one data-point per day for the chosen range (W=7, M=30, Y=365).

    Each point:
      {
        "date":     "2025-01-15",   <- YYYY-MM-DD for X-axis label
        "avg_mood": 3.4,            <- average mood value 1-5, or null if no logs
        "count":    12,             <- how many moods logged that day
        "label":    "calm"          <- dominant mood label for tooltip
      }

    Moods are stored with:
      - "mood_date": "YYYY-MM-DD"  (string, set by Flutter)
      - "value": int 1-5           (set by Flutter's moodValues map)
      - "user_mood": str           (e.g. "happy", fallback for value)
    """
    db = await get_database()

    days_map = {"W": 7, "M": 30, "Y": 365}
    num_days = days_map.get(range_key, 30)

    today  = datetime.utcnow().date()
    result = []

    for i in range(num_days - 1, -1, -1):
        day      = today - timedelta(days=i)
        date_str = day.strftime("%Y-%m-%d")

        moods = await db.moods.find({"mood_date": date_str}).to_list(length=None)

        if not moods:
            result.append({"date": date_str, "avg_mood": None, "count": 0, "label": None})
            continue

        values: list[float] = []
        label_counts: dict[str, int] = {}

        for m in moods:
            val = m.get("value")
            if val is None:
                raw_label = (m.get("user_mood") or "").lower()
                val = MOOD_VALUES.get(raw_label)
            if val is not None:
                values.append(float(val))

            mood_label = (m.get("user_mood") or "").lower()
            if mood_label:
                label_counts[mood_label] = label_counts.get(mood_label, 0) + 1

        avg      = round(sum(values) / len(values), 2) if values else None
        dominant = max(label_counts, key=label_counts.get) if label_counts else None

        result.append({
            "date":     date_str,
            "avg_mood": avg,
            "count":    len(moods),
            "label":    dominant,
        })

    return result


# ── User Management ───────────────────────────────────────────────────────────

async def get_all_users(skip: int = 0, limit: int = 50):
    db = await get_database()
    cursor = db.users.find(
        {"role": "user"}, {"password": 0}
    ).sort("created_at", -1).skip(skip).limit(limit)

    users = await cursor.to_list(length=limit)
    for u in users:
        u["_id"] = str(u["_id"])
    return users


async def get_all_professionals(skip: int = 0, limit: int = 50):
    db = await get_database()
    cursor = db.users.find(
        {"role": "professional"}, {"password": 0}
    ).sort("created_at", -1).skip(skip).limit(limit)

    professionals = await cursor.to_list(length=limit)
    result = []
    for p in professionals:
        result.append({
            "_id":              str(p["_id"]),
            "user_id":          p.get("user_id", ""),   # ← THIS WAS MISSING
            "user_name":        p.get("user_name", ""),
            "user_email":       p.get("user_email", ""),
            "professional_role": p.get("professional_role", p.get("specialty", "")),
            "is_approved":      p.get("is_approved", False),
            "is_active":        p.get("is_active", False),
            "disabled":         p.get("disabled", False),
            "created_at":       p["created_at"].isoformat()
                                if hasattr(p.get("created_at"), "isoformat")
                                else str(p.get("created_at", "")),
        })
    return result


async def toggle_user_active(user_id: str, disabled: bool):
    db = await get_database()
    result = await db.users.update_one(
        {"user_id": user_id},
        {"$set": {"disabled": disabled, "updated_at": datetime.utcnow()}},
    )
    if result.matched_count == 0:
        return None, "User not found"
    action = "deactivated" if disabled else "activated"
    logger.info(f"Admin {action} user {user_id}")
    return {"user_id": user_id, "disabled": disabled}, None


# ── Professional Approval ─────────────────────────────────────────────────────

async def approve_professional(professional_id: str, approve: bool):
    db = await get_database()
    
    # Try user_id first (UUID), then fall back to _id (ObjectId)
    result = await db.users.update_one(
        {"user_id": professional_id, "role": "professional"},
        {"$set": {"is_approved": approve, "is_active": approve, "reviewed_at": datetime.utcnow()}},
    )
    
    if result.matched_count == 0:
        # Fallback: try by MongoDB _id
        try:
            from bson import ObjectId
            result = await db.users.update_one(
                {"_id": ObjectId(professional_id), "role": "professional"},
                {"$set": {"is_approved": approve, "is_active": approve, "reviewed_at": datetime.utcnow()}},
            )
        except Exception:
            pass

    if result.matched_count == 0:
        return None, "Professional not found"
    
    return {"professional_id": professional_id, "is_approved": approve}, None


# ── Crisis Alerts ─────────────────────────────────────────────────────────────

async def get_all_crisis_alerts(resolved=None, skip: int = 0, limit: int = 50):
    db = await get_database()

    query = {}
    if resolved is not None:
        query["resolved"] = resolved

    cursor = db.crisis_alerts.find(query).sort("created_at", -1).skip(skip).limit(limit)
    alerts = await cursor.to_list(length=limit)

    result = []
    for a in alerts:
        user = await db.users.find_one({"user_id": a["user_id"]}, {"password": 0})
        a["_id"]        = str(a["_id"])
        a["user_email"] = user.get("user_email", "Unknown") if user else "Unknown"
        a["user_name"]  = user.get("user_name",  "Unknown") if user else "Unknown"
        result.append(a)
    return result


async def resolve_crisis_alert(alert_id: str):
    db = await get_database()
    try:
        oid = ObjectId(alert_id)
    except Exception:
        return None, "Invalid alert ID format"

    result = await db.crisis_alerts.update_one(
        {"_id": oid},
        {"$set": {"resolved": True, "resolved_at": datetime.utcnow()}},
    )
    if result.matched_count == 0:
        return None, "Alert not found"
    return {"alert_id": alert_id, "resolved": True}, None