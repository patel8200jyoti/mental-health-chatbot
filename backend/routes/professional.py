from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime
from bson import ObjectId
from typing import Optional
from uuid import uuid4

from database import get_database
from routes.auth import get_current_user
from models.professional import ProfessionalNote
from utils.security import hash_password

app = APIRouter(prefix="/professional", tags=["professional"])


def _prof_id(prof: dict) -> str:
    """Always return the UUID-based user_id for use in queries."""
    return prof["user_id"]


def _str_id(doc: dict) -> dict:
    if doc.get("_id"):
        doc["_id"] = str(doc["_id"])
    return doc


def _ago(dt: Optional[datetime]) -> str:
    if not dt:
        return ""
    diff = datetime.utcnow() - dt
    if diff.days > 30:
        return f"{diff.days // 30}mo ago"
    if diff.days > 0:
        return f"{diff.days}d ago"
    hours = diff.seconds // 3600
    if hours > 0:
        return f"{hours}h ago"
    return f"{diff.seconds // 60}m ago"


# ── Register (no auth needed) ─────────────────────────────────────────────────

@app.post("/register", status_code=201)
async def register_professional(body: dict):
    db = await get_database()

    email = body.get("user_email", "").strip().lower()
    if not email:
        raise HTTPException(400, "Email is required")

    existing = await db.users.find_one({"user_email": email})
    if existing:
        raise HTTPException(400, "Email already registered")

    password = body.get("password", "")
    if len(password) < 6:
        raise HTTPException(400, "Password must be at least 6 characters")

    professional = {
        "user_id":                     str(uuid4()),
        "user_email":                  email,
        "password":                    hash_password(password),
        "full_name":                   body.get("full_name", ""),
        "user_name":                   body.get("full_name", ""),
        "user_dob":                    body.get("user_dob", ""),
        "user_gender":                 body.get("user_gender", ""),
        "medical_registration_number": body.get("medical_registration_number", ""),
        "state_medical_council":       body.get("state_medical_council", ""),
        "year_of_registration":        body.get("year_of_registration", ""),
        "educational_qualifications":  body.get("educational_qualifications", ""),
        "specialty":                   body.get("educational_qualifications", ""),
        "role":                        "professional",
        "is_approved":                 False,   # admin must approve
        "nmr_verified":                False,
        "is_active":                   True,
        "disabled":                    False,
        "image_url":                   "",
        "experience_years":            0,
        "rating":                      5,
        "is_online":                   False,
        "can_connect_now":             True,
        "created_at":                  datetime.utcnow(),
    }

    await db.users.insert_one(professional)
    return {
        "success": True,
        "message": "Registration submitted. Awaiting admin approval.",
    }


# ── Own profile ───────────────────────────────────────────────────────────────

@app.get("/me")
async def get_me(prof=Depends(get_current_user)):
    return {
        "user_id":      prof["user_id"],
        "user_email":   prof["user_email"],
        # professionals use full_name; regular users use user_name
        "full_name":    prof.get("full_name", ""),
        "user_name":    prof.get("user_name", ""),
        "role":         prof.get("role", ""),
        "is_approved":  prof.get("is_approved", False),
        "disabled":     prof.get("disabled", False),
        "specialty":    prof.get("specialty", ""),
        "image_url":    prof.get("image_url", ""),
        "rating":       prof.get("rating", 5),
        "is_online":    prof.get("is_online", False),
    }


# ── Browse approved professionals (patient-facing) ────────────────────────────

@app.get("/")
async def list_professionals():
    db = await get_database()
    docs = await db.users.find(
        {"role": "professional", "is_approved": True, "disabled": False}
    ).to_list(length=200)
    return [
        {
            "user_id":      d["user_id"],
            "full_name":    d.get("full_name", ""),
            "specialty":    d.get("specialty", ""),
            "experience_years": d.get("experience_years", 0),
            "rating":       d.get("rating", 5),
            "is_online":    d.get("is_online", False),
            "image_url":    d.get("image_url", ""),
        }
        for d in docs
    ]


# ── Patient sends connection request ─────────────────────────────────────────

@app.post("/request")
async def request_professional(body: dict, user=Depends(get_current_user)):
    db = await get_database()
    professional_id = body.get("professional_id")
    if not professional_id:
        raise HTTPException(400, "professional_id required")

    existing = await db.professional_links.find_one({
        "professional_id": professional_id,
        "user_id": user["user_id"],
    })
    if existing:
        raise HTTPException(400, "Request already sent")

    await db.professional_links.insert_one({
        "professional_id": professional_id,
        "user_id":         user["user_id"],
        "status":          "pending",
        "created_at":      datetime.utcnow(),
    })
    return {"ok": True}


# ── Dashboard summary ─────────────────────────────────────────────────────────

@app.get("/dashboard/stats")
async def get_dashboard_stats(prof=Depends(get_current_user)):
    db = await get_database()
    prof_id = _prof_id(prof)

    total_patients = await db.professional_links.count_documents(
        {"professional_id": prof_id, "status": "accepted"}
    )
    pending_requests = await db.professional_links.count_documents(
        {"professional_id": prof_id, "status": "pending"}
    )

    patient_links = await db.professional_links.find(
        {"professional_id": prof_id, "status": "accepted"}, {"user_id": 1}
    ).to_list(length=1000)
    patient_ids = [l["user_id"] for l in patient_links]

    open_crisis = await db.crisis_alerts.count_documents(
        {"user_id": {"$in": patient_ids}, "resolved": {"$ne": True}}
    ) if patient_ids else 0

    streak_count = await db.users.count_documents(
        {"user_id": {"$in": patient_ids}, "mood_streak": {"$gt": 0}}
    ) if patient_ids else 0

    perm_ids = await _patients_with_journal_permission(db, prof_id)
    total_journals = await db.journals.count_documents(
        {"user_id": {"$in": perm_ids}}
    ) if perm_ids else 0

    return {
        "total_patients":   total_patients,
        "pending_requests": pending_requests,
        "open_crisis":      open_crisis,
        "streak_count":     streak_count,
        "total_journals":   total_journals,
    }


# ── Patients ──────────────────────────────────────────────────────────────────

@app.get("/patients")
async def get_patients(prof=Depends(get_current_user)):
    db = await get_database()
    prof_id = _prof_id(prof)

    links = await db.professional_links.find(
        {"professional_id": prof_id, "status": "accepted"}
    ).to_list(length=500)

    result = []
    for link in links:
        user = await db.users.find_one({"user_id": link["user_id"]})
        if not user:
            continue
        result.append({
            "user_id":       link["user_id"],
            # patients are regular users → user_name field
            "user_name":     user.get("user_name", ""),
            "user_email":    user.get("user_email", ""),
            "user_gender":   user.get("user_gender", ""),
            "user_dob":      str(user.get("user_dob", "")),
            "linked_at":     link.get("accepted_at", link.get("created_at")),
            "allow_mood":    link.get("allow_mood", False),
            "allow_journal": link.get("allow_journal", False),
            "disabled":      user.get("disabled", False),
        })
    return result


@app.get("/patients/pending")
async def get_pending_requests(prof=Depends(get_current_user)):
    db = await get_database()
    prof_id = _prof_id(prof)

    links = await db.professional_links.find(
        {"professional_id": prof_id, "status": "pending"}
    ).to_list(length=200)

    result = []
    for link in links:
        user = await db.users.find_one({"user_id": link["user_id"]})
        if not user:
            continue
        result.append({
            "user_id":      link["user_id"],
            "user_name":    user.get("user_name", ""),
            "user_email":   user.get("user_email", ""),
            "user_gender":  user.get("user_gender", ""),
            "requested_at": link.get("created_at"),
            "message":      link.get("message", ""),
        })
    return result


@app.post("/patients/{user_id}/respond")
async def respond_to_request(user_id: str, body: dict, prof=Depends(get_current_user)):
    db = await get_database()
    prof_id = _prof_id(prof)
    accept: bool = body.get("accept", False)

    link = await db.professional_links.find_one(
        {"professional_id": prof_id, "user_id": user_id, "status": "pending"}
    )
    if not link:
        raise HTTPException(404, "Request not found")

    if accept:
        await db.professional_links.update_one(
            {"_id": link["_id"]},
            {"$set": {"status": "accepted", "accepted_at": datetime.utcnow()}}
        )
    else:
        await db.professional_links.delete_one({"_id": link["_id"]})

    return {"ok": True}


@app.delete("/patients/{user_id}")
async def remove_patient(user_id: str, prof=Depends(get_current_user)):
    db = await get_database()
    prof_id = _prof_id(prof)
    await db.professional_links.delete_one(
        {"professional_id": prof_id, "user_id": user_id}
    )
    return {"ok": True}


# ── Patient detail ────────────────────────────────────────────────────────────

@app.get("/patients/{user_id}/profile")
async def get_patient_profile(user_id: str, prof=Depends(get_current_user)):
    db = await get_database()
    prof_id = _prof_id(prof)

    link = await db.professional_links.find_one(
        {"professional_id": prof_id, "user_id": user_id, "status": "accepted"}
    )
    if not link:
        raise HTTPException(403, "Patient not linked")

    user = await db.users.find_one({"user_id": user_id})
    if not user:
        raise HTTPException(404, "User not found")

    latest_mood = await db.moods.find_one(
        {"user_id": user_id}, sort=[("mood_date", -1)]
    )

    pipeline = [
        {"$match": {"user_id": user_id}},
        {"$group": {"_id": "$user_mood", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
    ]
    mood_dist = await db.moods.aggregate(pipeline).to_list(length=10)
    total_moods = await db.moods.count_documents({"user_id": user_id})
    total_journals = await db.journals.count_documents({"user_id": user_id})

    return {
        "user_id":        user_id,
        "user_name":      user.get("user_name", ""),
        "user_email":     user.get("user_email", ""),
        "user_gender":    user.get("user_gender", ""),
        "user_dob":       str(user.get("user_dob", "")),
        "mood_streak":    user.get("mood_streak", 0),
        "allow_mood":     link.get("allow_mood", False),
        "allow_journal":  link.get("allow_journal", False),
        "linked_at":      link.get("accepted_at", link.get("created_at")),
        "total_moods":    total_moods,
        "total_journals": total_journals,
        "latest_mood":    latest_mood.get("user_mood") if latest_mood else None,
        "latest_mood_date": str(latest_mood.get("mood_date", "")) if latest_mood else None,
        "mood_distribution": [{"mood": d["_id"], "count": d["count"]} for d in mood_dist],
    }


@app.get("/patients/{user_id}/moods")
async def get_patient_moods(user_id: str, prof=Depends(get_current_user)):
    db = await get_database()
    prof_id = _prof_id(prof)

    link = await db.professional_links.find_one(
        {"professional_id": prof_id, "user_id": user_id, "status": "accepted"}
    )
    if not link:
        raise HTTPException(403, "Patient not linked")
    if not link.get("allow_mood", False):
        raise HTTPException(403, "Patient has not shared mood data")

    moods = await db.moods.find(
        {"user_id": user_id}, sort=[("mood_date", -1)]
    ).to_list(length=90)

    return [
        {
            "date":       str(m.get("mood_date", ""))[:10],
            "mood":       m.get("user_mood", ""),
            "mood_score": m.get("mood_score", 0),
            "note":       m.get("mood_note", ""),
        }
        for m in moods
    ]


@app.get("/patients/{user_id}/journals")
async def get_patient_journals(user_id: str, prof=Depends(get_current_user)):
    db = await get_database()
    prof_id = _prof_id(prof)

    link = await db.professional_links.find_one(
        {"professional_id": prof_id, "user_id": user_id, "status": "accepted"}
    )
    if not link:
        raise HTTPException(403, "Patient not linked")
    if not link.get("allow_journal", False):
        raise HTTPException(403, "Patient has not shared journal data")

    journals = await db.journals.find(
        {"user_id": user_id}, sort=[("created_at", -1)]
    ).to_list(length=50)

    return [
        {
            "id":         str(j.get("_id", "")),
            "title":      j.get("title", ""),
            "content":    j.get("content", ""),
            "sentiment":  j.get("sentiment_score", 0),
            "moods":      j.get("detected_moods", []),
            "created_at": str(j.get("created_at", "")),
        }
        for j in journals
    ]


# ── Crisis alerts ─────────────────────────────────────────────────────────────

@app.get("/crisis")
async def get_crisis_alerts(resolved: bool = False, prof=Depends(get_current_user)):
    db = await get_database()
    prof_id = _prof_id(prof)

    links = await db.professional_links.find(
        {"professional_id": prof_id, "status": "accepted"}, {"user_id": 1}
    ).to_list(length=1000)
    patient_ids = [l["user_id"] for l in links]
    if not patient_ids:
        return []

    query = {"user_id": {"$in": patient_ids}}
    query["resolved"] = True if resolved else {"$ne": True}

    alerts = await db.crisis_alerts.find(query).sort("created_at", -1).to_list(length=50)
    result = []
    for a in alerts:
        user = await db.users.find_one({"user_id": a["user_id"]})
        result.append({
            "_id":        str(a["_id"]),
            "user_id":    a["user_id"],
            "user_name":  user.get("user_name", "Unknown") if user else "Unknown",
            "user_email": user.get("user_email", "") if user else "",
            "message":    a.get("message", ""),
            "resolved":   a.get("resolved", False),
            "created_at": str(a.get("created_at", "")),
        })
    return result


@app.post("/crisis/{alert_id}/resolve")
async def resolve_crisis(alert_id: str, prof=Depends(get_current_user)):
    db = await get_database()
    await db.crisis_alerts.update_one(
        {"_id": ObjectId(alert_id)},
        {"$set": {"resolved": True, "resolved_at": datetime.utcnow()}}
    )
    return {"ok": True}


# ── Notes ─────────────────────────────────────────────────────────────────────

@app.get("/patients/{user_id}/notes")
async def get_notes(user_id: str, prof=Depends(get_current_user)):
    db = await get_database()
    prof_id = _prof_id(prof)

    notes = await db.professional_notes.find(
        {"professional_id": prof_id, "user_id": user_id}
    ).sort("created_at", -1).to_list(length=100)

    return [
        {
            "_id":        str(n["_id"]),
            "note":       n.get("note", ""),
            "created_at": str(n.get("created_at", "")),
        }
        for n in notes
    ]


@app.post("/patients/{user_id}/notes")
async def add_note(user_id: str, body: ProfessionalNote, prof=Depends(get_current_user)):
    db = await get_database()
    prof_id = _prof_id(prof)

    await db.professional_notes.insert_one({
        "professional_id": prof_id,
        "user_id":         user_id,
        "note":            body.note,
        "created_at":      datetime.utcnow(),
    })
    return {"ok": True}


@app.delete("/patients/{user_id}/notes/{note_id}")
async def delete_note(user_id: str, note_id: str, prof=Depends(get_current_user)):
    db = await get_database()
    prof_id = _prof_id(prof)
    await db.professional_notes.delete_one(
        {"_id": ObjectId(note_id), "professional_id": prof_id}
    )
    return {"ok": True}


# ── Helpers ───────────────────────────────────────────────────────────────────

async def _patients_with_journal_permission(db, prof_id: str) -> list[str]:
    links = await db.professional_links.find(
        {"professional_id": prof_id, "status": "accepted", "allow_journal": True},
        {"user_id": 1}
    ).to_list(length=500)
    return [l["user_id"] for l in links]