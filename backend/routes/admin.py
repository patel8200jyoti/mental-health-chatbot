
from fastapi import APIRouter, Depends, HTTPException, Query
from routes.auth import get_current_user
from database import get_database
from datetime import datetime
from schemas.admin import _serialize_professional,_serialize_user


app = APIRouter(prefix="/admin", tags=["Admin"])


# ── Auth guard ────────────────────────────────────────────────────────────────

def require_admin(user=Depends(get_current_user)):
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admins only")
    return user


# ── Stats ─────────────────────────────────────────────────────────────────────

@app.get("/stats")
async def get_stats(user=Depends(require_admin)):
    db = await get_database()
    total_users         = await db.users.count_documents({"role": "user"})        
    total_professionals = await db.users.count_documents({"role": "professional", "is_approved": True}) 
    pending_approvals   = await db.users.count_documents({
        "role": "professional",
        "is_approved": False,
        "disabled": {"$ne": True}
    })
    total_journals = await db.journals.count_documents({})
    return {
        "total_users":         total_users,
        "total_professionals": total_professionals,
        "pending_approvals":   pending_approvals,
        "total_journals":      total_journals,
    }


@app.get("/stats/dashboard")
async def get_dashboard_stats(user=Depends(require_admin)):
    db = await get_database()
    total_messages   = await db.chat_messages.count_documents({})
    active_chats     = await db.chats.count_documents({})
    total_journals   = await db.journals.count_documents({})

    # Users with mood logged in last 7 days
    week_ago = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    from datetime import timedelta
    week_ago = datetime.utcnow() - timedelta(days=7)
    streak_users = await db.moods.distinct("user_id", {"created_at": {"$gte": week_ago}})

    return {
        "active_streak_count": len(streak_users),
        "active_chats":        active_chats,
        "total_messages":      total_messages,
        "total_journals":      total_journals,
    }

# -------- Mood Journal stats
@app.get("/stats/moods")
async def get_mood_trends(range: str = "M", user=Depends(require_admin)):
    from datetime import timedelta, date as date_type
    db = await get_database()

    days_map = {"W": 7, "M": 30, "Y": 365}
    num_days = days_map.get(range, 30)          # ✅ renamed to num_days — avoids shadowing
    since = datetime.utcnow() - timedelta(days=num_days)

    pipeline = [
        {"$match": {"mood_date": {"$gte": since}}},
        {"$group": {
            "_id": {
                "$dateToString": {"format": "%Y-%m-%d", "date": "$mood_date"}
            },
            "avg_mood":    {"$avg": "$mood_score"},
            "count":       {"$sum": 1},
            "label":       {"$first": "$user_mood"},
            "total_score": {"$sum": "$mood_score"},
        }},
        {"$sort": {"_id": 1}},
        {"$project": {
            "_id": 0,
            "date":        "$_id",
            "avg_mood":    {"$round": ["$avg_mood", 2]},
            "count":       1,
            "label":       1,
            "total_score": 1,
        }},
    ]

    results = await db.moods.aggregate(pipeline).to_list(length=400)

    # Fill missing days
    today     = datetime.utcnow().date()
    all_dates = {(today - timedelta(days=i)).strftime("%Y-%m-%d") for i in range(num_days)}  # ✅ num_days
    found     = {r["date"] for r in results}
    missing   = [
        {"date": d, "avg_mood": None, "count": 0, "label": None, "total_score": 0}
        for d in sorted(all_dates - found)
    ]

    return sorted(results + missing, key=lambda x: x["date"])


@app.get("/stats/moods/summary")
async def get_mood_summary(user=Depends(require_admin)):
    """
    Returns platform-wide mood summary:
    - overall avg mood score
    - mood distribution (count per mood label)
    - most common mood
    - total mood logs
    - users who logged mood today
    """
    from datetime import timedelta
    db = await get_database()

    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)

    pipeline = [
        {"$group": {
            "_id":         "$user_mood",
            "count":       {"$sum": 1},
            "avg_score":   {"$avg": "$mood_score"},
        }},
        {"$sort": {"count": -1}},
    ]
    distribution = await db.moods.aggregate(pipeline).to_list(length=10)

    total_logs   = sum(d["count"] for d in distribution)
    most_common  = distribution[0]["_id"] if distribution else None

    # overall avg
    avg_pipeline = [
        {"$group": {"_id": None, "avg": {"$avg": "$mood_score"}}}
    ]
    avg_result = await db.moods.aggregate(avg_pipeline).to_list(length=1)
    overall_avg = round(avg_result[0]["avg"], 2) if avg_result else 0

    # users who logged today
    today_users = await db.moods.distinct(
        "user_id", {"mood_date": {"$gte": today_start}}
    )

    return {
        "overall_avg_mood":  overall_avg,
        "total_logs":        total_logs,
        "most_common_mood":  most_common,
        "users_logged_today": len(today_users),
        "distribution": [
            {
                "mood":      d["_id"],
                "count":     d["count"],
                "avg_score": round(d["avg_score"], 2),
                "pct":       round(d["count"] / total_logs * 100, 1) if total_logs else 0,
            }
            for d in distribution
        ],
    }


@app.get("/stats/journals")
async def get_journal_stats(user=Depends(require_admin)):
    """
    Returns:
    - total journals
    - journals per day (last 30 days) for a trend line
    - sentiment distribution (positive/neutral/negative)
    - most common detected mood
    - avg sentiment score
    """
    from datetime import timedelta
    db = await get_database()

    since_30 = datetime.utcnow() - timedelta(days=30)

    # Trend — journals per day last 30 days
    trend_pipeline = [
        {"$match": {"created_at": {"$gte": since_30}}},
        {"$group": {
            "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
            "count": {"$sum": 1},
        }},
        {"$sort": {"_id": 1}},
        {"$project": {"_id": 0, "date": "$_id", "count": 1}},
    ]
    trend = await db.journals.aggregate(trend_pipeline).to_list(length=30)

    # Sentiment distribution
    sentiment_pipeline = [
        {"$group": {
            "_id":   None,
            "avg_sentiment": {"$avg": "$sentiment_score"},
            "positive":      {"$sum": {"$cond": [{"$gt": ["$sentiment_score", 0]}, 1, 0]}},
            "neutral":       {"$sum": {"$cond": [{"$eq": ["$sentiment_score", 0]}, 1, 0]}},
            "negative":      {"$sum": {"$cond": [{"$lt": ["$sentiment_score", 0]}, 1, 0]}},
            "total":         {"$sum": 1},
        }}
    ]
    sent = await db.journals.aggregate(sentiment_pipeline).to_list(length=1)
    sent = sent[0] if sent else {}

    # Most common detected mood from journals
    mood_pipeline = [
        {"$match": {"mood_detected": {"$ne": None}}},
        {"$group": {"_id": "$mood_detected", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 5},
    ]
    top_moods = await db.journals.aggregate(mood_pipeline).to_list(length=5)

    total = await db.journals.count_documents({})

    return {
        "total_journals":    total,
        "avg_sentiment":     round(sent.get("avg_sentiment") or 0, 2),
        "positive_count":    sent.get("positive", 0),
        "neutral_count":     sent.get("neutral", 0),
        "negative_count":    sent.get("negative", 0),
        "trend_last_30":     trend,
        "top_moods_detected": [
            {"mood": m["_id"], "count": m["count"]} for m in top_moods
        ],
    }


# ── Users ─────────────────────────────────────────────────────────────────────

@app.get("/users")
async def get_users(
    skip: int = 0, limit: int = 50,
    user=Depends(require_admin),
):
    db = await get_database()
    cursor = db.users.find({"role": "user"}).skip(skip).limit(limit)
    users = await cursor.to_list(length=limit)
    return [_serialize_user(u) for u in users]


@app.patch("/users/{user_id}/activate")
async def toggle_user(user_id: str, disabled: bool, user=Depends(require_admin)):
    db = await get_database()
    result = await db.users.update_one(
        {"user_id": user_id},
        {"$set": {"disabled": disabled, "is_active": not disabled}},
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
    return {"user_id": user_id, "disabled": disabled}


# ── Professionals ─────────────────────────────────────────────────────────────

@app.get("/professionals")
async def get_professionals(
    skip: int = 0, limit: int = 50,
    user=Depends(require_admin),
):
    """
    Returns ALL professional fields including NMR-verifiable ones
    so DoctorVerificationPage can display them without a second request.

    Fields returned:
      _id, user_id, created_at
      full_name, user_name, user_email, user_dob, user_gender
      medical_registration_number, state_medical_council,
      year_of_registration, educational_qualifications
      professional_role, specialty
      is_approved, nmr_verified, is_active, disabled
      image_url, experience_years, rating
    """
    db = await get_database()
    cursor = db.users.find({"role": "professional"}).skip(skip).limit(limit)
    professionals = await cursor.to_list(length=limit)
    return [_serialize_professional(p) for p in professionals]


@app.patch("/professionals/{professional_id}/approve")
async def approve_professional(
    professional_id: str,
    approve: bool,
    user=Depends(require_admin),
):
    """
    Approve or reject a professional by user_id OR _id string.
    Sets is_approved, is_active, and nmr_verified on approval.
    """
    db = await get_database()

    # Try user_id first, then fall back to string _id match
    result = await db.users.update_one(
        {"user_id": professional_id, "role": "professional"},
        {"$set": {
            "is_approved":  approve,
            "is_active":    approve,
            "nmr_verified": approve,
            "disabled":     False,
        }},
    )

    # Fallback: some older records may be looked up by _id string
    if result.matched_count == 0:
        from bson import ObjectId
        try:
            result = await db.users.update_one(
                {"_id": ObjectId(professional_id), "role": "professional"},
                {"$set": {
                    "is_approved":  approve,
                    "is_active":    approve,
                    "nmr_verified": approve,
                    "disabled":     False,
                }},
            )
        except Exception:
            pass

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Professional not found")

    return {"professional_id": professional_id, "approved": approve}


# ── Crisis alerts ─────────────────────────────────────────────────────────────

@app.get("/crisis")
async def get_crisis_alerts(
    resolved: bool = None,
    skip: int = 0,
    limit: int = 50,
    user=Depends(require_admin),
):
    db = await get_database()
    query = {}
    if resolved is not None:
        query["resolved"] = resolved
    cursor = db.crisis_alerts.find(query).sort("created_at", -1).skip(skip).limit(limit)
    alerts = await cursor.to_list(length=limit)

    result = []
    for a in alerts:
        uid = a.get("user_id")
        u   = await db.users.find_one({"user_id": uid}) if uid else None
        result.append({
            "_id":        str(a["_id"]),
            "user_id":    uid,
            "user_name":  u.get("user_name", "Unknown") if u else "Unknown",
            "user_email": u.get("user_email", "")       if u else "",
            "message":    a.get("message", ""),
            "resolved":   a.get("resolved", False),
            "created_at": a["created_at"].isoformat() if hasattr(a.get("created_at"), "isoformat") else str(a.get("created_at", "")),
        })
    return result


@app.patch("/crisis/{alert_id}/resolve")
async def resolve_alert(alert_id: str, user=Depends(require_admin)):
    from bson import ObjectId
    db = await get_database()
    try:
        result = await db.crisis_alerts.update_one(
            {"_id": ObjectId(alert_id)},
            {"$set": {"resolved": True, "resolved_at": datetime.utcnow()}},
        )
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid alert ID")
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Alert not found")
    return {"alert_id": alert_id, "resolved": True}

@app.get("/stats/moods/debug")
async def debug_moods(user=Depends(require_admin)):
    db = await get_database()
    sample = await db.moods.find_one({})
    count  = await db.moods.count_documents({})
    return {
        "total_docs": count,
        "sample_mood_date": str(sample.get("mood_date")) if sample else None,
        "sample_mood_score": sample.get("mood_score") if sample else None,
        "sample_keys": list(sample.keys()) if sample else [],
    }
# # ── Serializers ───────────────────────────────────────────────────────────────

# def _serialize_user(u: dict) -> dict:
#     return {
#         "_id":        str(u["_id"]),
#         "user_id":    u.get("user_id", ""),
#         "user_name":  u.get("user_name", ""),
#         "user_email": u.get("user_email", ""),
#         "user_dob":   u.get("user_dob", ""),
#         "user_gender":u.get("user_gender", ""),
#         "is_active":  u.get("is_active", False),
#         "disabled":   u.get("disabled", False),
#         "created_at": u["created_at"].isoformat() if hasattr(u.get("created_at"), "isoformat") else str(u.get("created_at", "")),
#     }


# def _serialize_professional(p: dict) -> dict:
#     """
#     Returns every field DoctorVerificationPage needs.
#     Never omit NMR fields — even if empty string.
#     """
#     return {
#         # Identity (both _id and user_id returned so Flutter can use either)
#         "_id":       str(p["_id"]),
#         "user_id":   p.get("user_id", ""),

#         # Personal
#         "full_name":   p.get("full_name", p.get("user_name", "")),
#         "user_name":   p.get("user_name", p.get("full_name", "")),
#         "user_email":  p.get("user_email", ""),
#         "user_dob":    p.get("user_dob", ""),
#         "user_gender": p.get("user_gender", ""),

#         # ── NMR fields ── these are what the verification page shows ──────
#         "medical_registration_number": p.get("medical_registration_number", ""),
#         "state_medical_council":       p.get("state_medical_council", ""),
#         "year_of_registration":        p.get("year_of_registration", ""),
#         "educational_qualifications":  p.get("educational_qualifications", ""),

#         # Role
#         "professional_role": p.get("professional_role", p.get("specialty", "")),
#         "specialty":         p.get("specialty", p.get("professional_role", "")),

#         # Status
#         "is_approved":  p.get("is_approved", False),
#         "nmr_verified": p.get("nmr_verified", False),
#         "is_active":    p.get("is_active", False),
#         "disabled":     p.get("disabled", False),

#         # Display
#         "image_url":        p.get("image_url", ""),
#         "experience_years": p.get("experience_years", 0),
#         "rating":           p.get("rating", 5.0),
#         "is_online":        p.get("is_online", False),
#         "can_connect_now":  p.get("can_connect_now", True),

#         "created_at": p["created_at"].isoformat() if hasattr(p.get("created_at"), "isoformat") else str(p.get("created_at", "")),
#     }