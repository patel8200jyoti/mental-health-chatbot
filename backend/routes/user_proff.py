"""
routes/user_professional.py

User-facing endpoints for their linked professional portal.
  GET  /my-doctor/link/{prof_id}              ← link info + permissions
  PUT  /my-doctor/link/{prof_id}/permissions  ← update allow_mood / allow_journal
  DEL  /my-doctor/link/{prof_id}              ← unlink
  GET  /my-doctor/links                       ← all my links (any status)
  GET  /my-doctor/{prof_id}/profile           ← professional's public profile

  POST /my-doctor/{prof_id}/sessions          ← request a session
  GET  /my-doctor/{prof_id}/sessions          ← list sessions

  GET  /my-doctor/{prof_id}/messages          ← portal messages
  POST /my-doctor/{prof_id}/messages          ← send a message

  DELETE /my-doctor/request/{prof_id}         ← cancel pending request
"""

from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime
from bson import ObjectId
from pydantic import BaseModel
from typing import Optional

from database import get_database
from routes.auth import get_current_user

app = APIRouter(prefix="/my-doctor", tags=["user-doctor"])


# ── Pydantic models ───────────────────────────────────────────────────────────

class PermissionsUpdate(BaseModel):
    allow_mood:    bool = False
    allow_journal: bool = False


class SessionRequest(BaseModel):
    session_date: str          # ISO8601 string
    session_type: str = "Consultation"
    note:         Optional[str] = None


class MessageBody(BaseModel):
    text: str


# ── Links ─────────────────────────────────────────────────────────────────────

@app.get("/links")
async def get_my_links(user=Depends(get_current_user)):
    """All link records (any status) for the current user."""
    db = await get_database()
    links = await db.professional_links.find(
        {"user_id": user["user_id"]}
    ).to_list(length=100)

    result = []
    for l in links:
        prof = await db.users.find_one({"user_id": l["professional_id"]})
        result.append({
            "professional_id":       l["professional_id"],
            "professional_user_id":  l["professional_id"],
            "professional_name":     prof.get("user_name", "") if prof else "",
            "status":                l.get("status", "pending"),
            "allow_mood":            l.get("allow_mood", False),
            "allow_journal":         l.get("allow_journal", False),
            "accepted_at":           _iso(l.get("accepted_at")),
            "created_at":            _iso(l.get("created_at")),
        })
    return result


@app.get("/link/{prof_id}")
async def get_link_with(prof_id: str, user=Depends(get_current_user)):
    db = await get_database()
    link = await db.professional_links.find_one(
        {"user_id": user["user_id"], "professional_id": prof_id}
    )
    if not link:
        raise HTTPException(404, "No link found with this professional")
    return {
        "professional_id": prof_id,
        "status":          link.get("status", "pending"),
        "allow_mood":      link.get("allow_mood", False),
        "allow_journal":   link.get("allow_journal", False),
        "accepted_at":     _iso(link.get("accepted_at")),
        "created_at":      _iso(link.get("created_at")),
    }


@app.put("/link/{prof_id}/permissions")
async def update_permissions(
    prof_id: str,
    body: PermissionsUpdate,
    user=Depends(get_current_user),
):
    db = await get_database()
    link = await db.professional_links.find_one(
        {"user_id": user["user_id"],
         "professional_id": prof_id,
         "status": "accepted"}
    )
    if not link:
        raise HTTPException(404, "Active link not found")

    await db.professional_links.update_one(
        {"_id": link["_id"]},
        {"$set": {
            "allow_mood":    body.allow_mood,
            "allow_journal": body.allow_journal,
            "permissions_updated_at": datetime.utcnow(),
        }}
    )
    return {"ok": True}


@app.delete("/link/{prof_id}")
async def unlink_professional(prof_id: str, user=Depends(get_current_user)):
    db = await get_database()
    await db.professional_links.delete_one(
        {"user_id": user["user_id"], "professional_id": prof_id}
    )
    return {"ok": True}


@app.delete("/request/{prof_id}")
async def cancel_request(prof_id: str, user=Depends(get_current_user)):
    db = await get_database()
    await db.professional_links.delete_one(
        {"user_id": user["user_id"],
         "professional_id": prof_id,
         "status": "pending"}
    )
    return {"ok": True}


# ── Professional public profile ───────────────────────────────────────────────

@app.get("/{prof_id}/profile")
async def get_prof_profile(prof_id: str, user=Depends(get_current_user)):
    db = await get_database()
    prof = await db.users.find_one(
        {"user_id": prof_id, "role": "professional", "is_approved": True}
    )
    if not prof:
        raise HTTPException(404, "Professional not found")

    # Strip sensitive fields
    return {
        "user_id":                     prof_id,
        "name":                        prof.get("user_name", ""),
        "specialty":                   prof.get("specialty", prof.get("educational_qualifications", "")),
        "medical_registration_number": prof.get("medical_registration_number", ""),
        "state_medical_council":       prof.get("state_medical_council", ""),
        "year_of_registration":        prof.get("year_of_registration", ""),
        "educational_qualifications":  prof.get("educational_qualifications", ""),
        "experience_years":            prof.get("experience_years", 0),
        "rating":                      prof.get("rating", 5.0),
        "is_online":                   prof.get("is_online", False),
    }


# ── Sessions ──────────────────────────────────────────────────────────────────

@app.post("/{prof_id}/sessions")
async def request_session(
    prof_id: str,
    body: SessionRequest,
    user=Depends(get_current_user),
):
    db = await get_database()
    # Require active link
    link = await db.professional_links.find_one(
        {"user_id": user["user_id"], "professional_id": prof_id, "status": "accepted"}
    )
    if not link:
        raise HTTPException(403, "You must be linked to this professional")

    try:
        session_dt = datetime.fromisoformat(body.session_date.replace("Z", "+00:00"))
    except ValueError:
        raise HTTPException(400, "Invalid date format")

    session = {
        "user_id":         user["user_id"],
        "professional_id": prof_id,
        "session_date":    session_dt,
        "session_type":    body.session_type,
        "note":            body.note or "",
        "status":          "pending",      # pending | confirmed | rejected | completed
        "created_at":      datetime.utcnow(),
    }
    result = await db.sessions.insert_one(session)
    return {"ok": True, "session_id": str(result.inserted_id)}


@app.get("/{prof_id}/sessions")
async def get_sessions(prof_id: str, user=Depends(get_current_user)):
    db = await get_database()
    sessions = await db.sessions.find(
        {"user_id": user["user_id"], "professional_id": prof_id}
    ).sort("session_date", -1).to_list(length=50)

    return [
        {
            "_id":          str(s["_id"]),
            "session_date": _iso(s.get("session_date")),
            "session_type": s.get("session_type", ""),
            "note":         s.get("note", ""),
            "status":       s.get("status", "pending"),
            "created_at":   _iso(s.get("created_at")),
        }
        for s in sessions
    ]


# ── Portal messages ───────────────────────────────────────────────────────────

@app.post("/{prof_id}/messages")
async def send_message(
    prof_id: str,
    body: MessageBody,
    user=Depends(get_current_user),
):
    db = await get_database()
    link = await db.professional_links.find_one(
        {"user_id": user["user_id"], "professional_id": prof_id, "status": "accepted"}
    )
    if not link:
        raise HTTPException(403, "You must be linked to this professional")

    await db.portal_messages.insert_one({
        "user_id":         user["user_id"],
        "professional_id": prof_id,
        "sender":          "user",
        "text":            body.text,
        "created_at":      datetime.utcnow(),
        "read":            False,
    })
    return {"ok": True}


@app.get("/{prof_id}/messages")
async def get_messages(prof_id: str, user=Depends(get_current_user)):
    db = await get_database()
    # Mark professional messages as read
    await db.portal_messages.update_many(
        {"user_id": user["user_id"],
         "professional_id": prof_id,
         "sender": "professional", "read": False},
        {"$set": {"read": True}}
    )

    msgs = await db.portal_messages.find(
        {"user_id": user["user_id"], "professional_id": prof_id}
    ).sort("created_at", 1).to_list(length=200)

    return [
        {
            "_id":        str(m["_id"]),
            "sender":     m.get("sender", "user"),
            "text":       m.get("text", ""),
            "created_at": _iso(m.get("created_at")),
            "read":       m.get("read", False),
        }
        for m in msgs
    ]


# ── Helpers ───────────────────────────────────────────────────────────────────

def _iso(dt) -> Optional[str]:
    if dt is None:
        return None
    if isinstance(dt, datetime):
        return dt.isoformat()
    return str(dt)