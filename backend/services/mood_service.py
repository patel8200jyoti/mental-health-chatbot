from datetime import timedelta, date, datetime
from database import get_database
from schemas.mood import mood_entity, mood_schema, to_datetime
import logging

logger = logging.getLogger(__name__)


# ── Create / update mood ──────────────────────────────────────────────────────

async def create_mood(mood, user):
    db = await get_database()

    mood_date = to_datetime(mood.mood_date or date.today())
    existing  = await db.moods.find_one({"user_id": user["user_id"], "mood_date": mood_date})
    mood_doc  = mood_entity(mood.model_dump(), user["user_id"])

    if existing:
        await db.moods.update_one(
            {"user_id": user["user_id"], "mood_date": mood_date},
            {"$set": {
                "user_mood":  mood_doc["user_mood"],
                "mood_score": mood_doc["mood_score"],
                "created_at": datetime.utcnow(),
            }},
        )
        logger.info("Mood entry updated for user today")
        created = await db.moods.find_one({"user_id": user["user_id"], "mood_date": mood_date})
    else:
        await db.moods.insert_one(mood_doc)
        logger.info("Mood entry created for the user")
        created = await db.moods.find_one({"user_id": user["user_id"], "mood_date": mood_date})

    return mood_schema(created)


# ── Last 7 days (original endpoint — kept for backward compat) ────────────────

async def get_week_moods(user):
    db    = await get_database()
    today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    week  = today - timedelta(days=7)

    moods  = db.moods.find({"user_id": user["user_id"], "mood_date": {"$gte": week}})
    result = []
    async for mood in moods:
        result.append(mood_schema(mood))
    return result


# ── ALL mood history ──────────────────────────────────────────────────────────

async def get_all_moods(user):
    """Return every mood entry for the user, sorted oldest → newest."""
    db    = await get_database()
    moods = db.moods.find(
        {"user_id": user["user_id"]},
        sort=[("mood_date", 1)],
    )
    result = []
    async for mood in moods:
        result.append(mood_schema(mood))
    return result


# ── Aggregated stats: weekly + monthly ───────────────────────────────────────

def _iso_week(dt: datetime) -> int:
    """Return ISO week number (1-53) for a datetime."""
    return dt.isocalendar()[1]


async def get_mood_stats(user):
    """
    Return pre-aggregated daily, weekly and monthly averages.

    Response shape:
    {
      "daily":   [ { "date": "2025-06-07", "avg_score": 4.5 }, ... ],
      "weekly":  [ { "year": 2025, "week": 23,  "avg_score": 4.2 }, ... ],
      "monthly": [ { "year": 2025, "month": 6,  "avg_score": 4.0 }, ... ],
    }
    """
    db    = await get_database()
    moods = db.moods.find(
        {"user_id": user["user_id"]},
        sort=[("mood_date", 1)],
    )

    # Buckets
    daily:   dict[str, list[int]] = {}   # "YYYY-MM-DD" → [scores]
    weekly:  dict[tuple, list[int]] = {} # (year, week)  → [scores]
    monthly: dict[tuple, list[int]] = {} # (year, month) → [scores]

    async for mood in moods:
        score = mood.get("mood_score", 4)
        if not isinstance(score, (int, float)):
            score = 4
        score = int(score)

        raw_date = mood.get("mood_date")
        if isinstance(raw_date, str):
            try:
                dt = datetime.fromisoformat(raw_date)
            except ValueError:
                continue
        elif isinstance(raw_date, (datetime, date)):
            dt = to_datetime(raw_date)
        else:
            continue

        # Daily
        day_key = dt.strftime("%Y-%m-%d")
        daily.setdefault(day_key, []).append(score)

        # Weekly  (ISO week)
        wk_key = (dt.year, _iso_week(dt))
        weekly.setdefault(wk_key, []).append(score)

        # Monthly
        mo_key = (dt.year, dt.month)
        monthly.setdefault(mo_key, []).append(score)

    def avg(lst: list[int]) -> float:
        return round(sum(lst) / len(lst), 2) if lst else 0.0

    return {
        "daily": [
            {"date": k, "avg_score": avg(v)}
            for k, v in sorted(daily.items())
        ],
        "weekly": [
            {"year": k[0], "week": k[1], "avg_score": avg(v)}
            for k, v in sorted(weekly.items())
        ],
        "monthly": [
            {"year": k[0], "month": k[1], "avg_score": avg(v)}
            for k, v in sorted(monthly.items())
        ],
    }


# ── Streak ────────────────────────────────────────────────────────────────────

async def calculate_streak(user):
    db    = await get_database()
    moods = db.moods.find({"user_id": user["user_id"]}, sort=[("mood_date", -1)])

    streak      = 0
    today       = date.today()
    current_day = today

    async for mood in moods:
        mood_date = mood["mood_date"]
        if isinstance(mood_date, datetime):
            mood_date = mood_date.date()

        if mood_date == current_day:
            streak      += 1
            current_day -= timedelta(days=1)
        else:
            break

    logger.info(f"Calculated mood streak: {streak}")
    return {"current_streak": streak}