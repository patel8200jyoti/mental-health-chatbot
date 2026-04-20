"""
services/professional_service.py — complete file

Handles all database logic for the professional ↔ patient flow:
  - Registration & profile
  - Link requests (send, respond, list pending)
  - Patient data access (moods, journals, crisis alerts, emotion trends)
  - Professional notes
"""

from database import get_database
from typing import Optional
from datetime import datetime
from uuid import uuid4
from utils.security import hash_password
import logging
from datetime import datetime
logger = logging.getLogger(__name__)


# ── Professional Auth ─────────────────────────────────────────────────────────



async def register_professional(
    full_name: str,
    medical_registration_number: str,
    state_medical_council: str,
    year_of_registration: str,
    educational_qualifications: str,
    user_email: str,
    password: str,
    user_dob=None,
    user_gender=None,
):
    db = await get_database()

    # Check duplicate email
    if await db.users.find_one({"user_email": user_email}):
        return None, "Email already exists"

    # Check duplicate registration number
    if await db.users.find_one({"medical_registration_number": medical_registration_number}):
        return None, "Registration number already registered"

    # Build the MongoDB document — these are the fields saved to the database
    doc = {
        "user_id":    str(uuid4()),
        "created_at": datetime.utcnow(),

        # ── who they are ──────────────────────────────
        "full_name":   full_name,
        "user_email":  user_email,
        "password":    hash_password(password),
        "user_dob":    str(user_dob) if user_dob else None,
        "user_gender": user_gender,

        # ── NMR fields (shown on admin verification page) ──
        "medical_registration_number": medical_registration_number,
        "state_medical_council":       state_medical_council,
        "year_of_registration":        year_of_registration,
        "educational_qualifications":  educational_qualifications,

        # ── status fields ─────────────────────────────
        "role":         "professional",
        "is_approved":  False,           # admin must approve
        "nmr_verified": False,           # admin sets True after NMR check
        "is_active":    False,
        "disabled":     False,

        # ── portal defaults ───────────────────────────
        "specialty":        educational_qualifications,
        "image_url":        "",
        "experience_years": 0,
        "rating":           5.0,
        "is_online":        False,
        "can_connect_now":  True,
    }

    await db.users.insert_one(doc)

    # Never return password to Flutter
    doc.pop("password", None)
    doc["_id"] = str(doc.get("_id", ""))

    return {"success": True, "message": "Registration submitted", "user_id": doc["user_id"]}, None


# ── Link Request (Patient → Professional) ─────────────────────────────────────

async def send_link_request(patient_id: str, professional_id: str):
    """
    Patient requests to connect with a professional.
    Validates that the professional exists and is approved.
    Prevents duplicate pending/accepted requests.
    """
    db = await get_database()

    professional = await db.users.find_one({
        "user_id":     professional_id,
        "role":        "professional",
        "is_approved": True,
    })
    if not professional:
        return None, "Professional not found or not yet approved"

    existing = await db.link_requests.find_one({
        "patient_id":      patient_id,
        "professional_id": professional_id,
        "status":          {"$in": ["pending", "accepted"]},
    })
    if existing:
        return None, "A request to this professional already exists"

    request = {
        "request_id":      str(uuid4()),
        "patient_id":      patient_id,
        "professional_id": professional_id,
        "status":          "pending",
        "created_at":      datetime.utcnow(),
    }
    await db.link_requests.insert_one(request)
    request["_id"] = str(request.get("_id", ""))
    logger.info(
        f"Link request created: patient={patient_id} → professional={professional_id}"
    )
    return request, None


async def respond_to_link_request(
    request_id: str, professional_id: str, action: str
):
    """
    Professional accepts or rejects a pending link request.
    action: 'accepted' | 'rejected'
    On acceptance, patient appears in get_my_patients().
    """
    db = await get_database()

    request = await db.link_requests.find_one({
        "request_id":      request_id,
        "professional_id": professional_id,
        "status":          "pending",
    })
    if not request:
        return None, "Request not found or already handled"

    await db.link_requests.update_one(
        {"request_id": request_id},
        {"$set": {"status": action, "responded_at": datetime.utcnow()}},
    )
    logger.info(
        f"Link request {request_id} {action} by professional {professional_id}"
    )
    return {"request_id": request_id, "status": action}, None


async def get_pending_requests(professional_id: str):
    """
    All pending patient requests for a professional, enriched with patient info.
    Shown in the 'New Patient Requests' section of ProfessionalPortal.
    """
    db = await get_database()
    cursor = db.link_requests.find(
        {"professional_id": professional_id, "status": "pending"},
    ).sort("created_at", -1)

    requests = await cursor.to_list(length=50)
    result = []
    for r in requests:
        patient = await db.users.find_one({"user_id": r["patient_id"]})
        result.append({
            "request_id":    r["request_id"],
            "patient_id":    r["patient_id"],
            "patient_name":  patient.get("user_name", "Unknown") if patient else "Unknown",
            "patient_email": patient.get("user_email", "")       if patient else "",
            "created_at":    r["created_at"].isoformat() if hasattr(r["created_at"], "isoformat") else str(r["created_at"]),
        })
    return result


async def get_my_patients(professional_id: str):
    """
    All accepted patients linked to a professional.
    Only appears after professional accepts the request.
    """
    db = await get_database()
    cursor = db.link_requests.find({
        "professional_id": professional_id,
        "status":          "accepted",
    })
    requests = await cursor.to_list(length=100)

    patients = []
    for r in requests:
        patient = await db.users.find_one({"user_id": r["patient_id"]})
        if patient:
            patients.append({
                "patient_id":    r["patient_id"],
                "patient_name":  patient.get("user_name", "Unknown"),
                "patient_email": patient.get("user_email", ""),
                "linked_since":  r.get("responded_at", "").isoformat()
                                 if hasattr(r.get("responded_at"), "isoformat")
                                 else str(r.get("responded_at", "")),
            })
    return patients


# ── Internal link check ───────────────────────────────────────────────────────

async def is_linked(professional_id: str, patient_id: str) -> bool:
    """Returns True only if an accepted link exists between them."""
    db = await get_database()
    link = await db.link_requests.find_one({
        "professional_id": professional_id,
        "patient_id":      patient_id,
        "status":          "accepted",
    })
    return link is not None


# ── Patient Data Access ───────────────────────────────────────────────────────

async def get_patient_moods(professional_id: str, patient_id: str):
    """Mood history — requires accepted link."""
    if not await is_linked(professional_id, patient_id):
        return None, "Access denied: no accepted link with this patient"
    db = await get_database()
    cursor = db.moods.find(
        {"user_id": patient_id},
        sort=[("mood_date", -1)],
    )
    moods = await cursor.to_list(length=60)
    for m in moods:
        m["_id"] = str(m["_id"])
    return moods, None


async def get_patient_journals(professional_id: str, patient_id: str):
    """Journal entries — requires accepted link."""
    if not await is_linked(professional_id, patient_id):
        return None, "Access denied: no accepted link with this patient"
    db = await get_database()
    cursor = db.journals.find(
        {"user_id": patient_id},
        sort=[("created_at", -1)],
    )
    journals = await cursor.to_list(length=50)
    for j in journals:
        j["_id"] = str(j["_id"])
    return journals, None


async def get_patient_crisis_alerts(professional_id: str, patient_id: str):
    """Crisis/urgent alerts — requires accepted link."""
    if not await is_linked(professional_id, patient_id):
        return None, "Access denied: no accepted link with this patient"
    db = await get_database()
    cursor = db.crisis_alerts.find(
        {"user_id": patient_id},
        sort=[("created_at", -1)],
    )
    alerts = await cursor.to_list(length=50)
    for a in alerts:
        a["_id"] = str(a["_id"])
    return alerts, None


async def get_patient_emotion_trends(professional_id: str, patient_id: str):
    """
    Aggregated emotion counts from chat_messages.
    Used for the emotion trends chart/view in the professional portal.
    Requires accepted link.
    """
    if not await is_linked(professional_id, patient_id):
        return None, "Access denied: no accepted link with this patient"
    db = await get_database()
    pipeline = [
        {"$match": {
            "user_id": patient_id,
            "role":    "user",
            "emotion": {"$ne": None},
        }},
        {"$group": {"_id": "$emotion", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
    ]
    trends = await db.chat_messages.aggregate(pipeline).to_list(length=20)
    return [{"emotion": t["_id"], "count": t["count"]} for t in trends], None


# ── Professional Notes ────────────────────────────────────────────────────────

async def add_note(professional_id: str, patient_id: str, note_text: str):
    """Add a clinical note for a linked patient."""
    if not await is_linked(professional_id, patient_id):
        return None, "Access denied: no accepted link with this patient"
    db = await get_database()
    note = {
        "note_id":         str(uuid4()),
        "professional_id": professional_id,
        "patient_id":      patient_id,
        "note":            note_text,
        "created_at":      datetime.utcnow(),
    }
    await db.professional_notes.insert_one(note)
    note["_id"] = str(note.get("_id", ""))
    logger.info(
        f"Note added by professional={professional_id} for patient={patient_id}"
    )
    return note, None


async def get_notes(professional_id: str, patient_id: str):
    """Get all notes written by this professional for a linked patient."""
    if not await is_linked(professional_id, patient_id):
        return None, "Access denied: no accepted link with this patient"
    db = await get_database()
    cursor = db.professional_notes.find(
        {"professional_id": professional_id, "patient_id": patient_id},
        sort=[("created_at", -1)],
    )
    notes = await cursor.to_list(length=50)
    for n in notes:
        n["_id"] = str(n["_id"])
    return notes, None

async def get_professional_me(professional_id: str):
    """
    Returns the profile of a professional by user_id.
    Used by /professional/me endpoint.
    """
    db = await get_database()
    professional = await db.users.find_one({"user_id": professional_id, "role": "professional"})
    if not professional:
        return None, "Professional not found"

    # Remove sensitive info
    professional.pop("password", None)
    professional["_id"] = str(professional.get("_id", ""))

    return professional, None