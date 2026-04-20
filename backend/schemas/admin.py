def _serialize_user(u: dict) -> dict:
    return {
        "_id":        str(u["_id"]),
        "user_id":    u.get("user_id", ""),
        "user_name":  u.get("user_name", ""),
        "user_email": u.get("user_email", ""),
        "user_dob":   u.get("user_dob", ""),
        "user_gender":u.get("user_gender", ""),
        "is_active":  u.get("is_active", False),
        "disabled":   u.get("disabled", False),
        "created_at": u["created_at"].isoformat() if hasattr(u.get("created_at"), "isoformat") else str(u.get("created_at", "")),
    }


def _serialize_professional(p: dict) -> dict:
    """
    Returns every field DoctorVerificationPage needs.
    Never omit NMR fields — even if empty string.
    """
    return {
        # Identity (both _id and user_id returned so Flutter can use either)
        "_id":       str(p["_id"]),
        "user_id":   p.get("user_id", ""),

        # Personal
        "full_name":   p.get("full_name", p.get("user_name", "")),
        "user_name":   p.get("user_name", p.get("full_name", "")),
        "user_email":  p.get("user_email", ""),
        "user_dob":    p.get("user_dob", ""),
        "user_gender": p.get("user_gender", ""),

        # ── NMR fields ── these are what the verification page shows ──────
        "medical_registration_number": p.get("medical_registration_number", ""),
        "state_medical_council":       p.get("state_medical_council", ""),
        "year_of_registration":        p.get("year_of_registration", ""),
        "educational_qualifications":  p.get("educational_qualifications", ""),

        # Role
        "professional_role": p.get("professional_role", p.get("specialty", "")),
        "specialty":         p.get("specialty", p.get("professional_role", "")),

        # Status
        "is_approved":  p.get("is_approved", False),
        "nmr_verified": p.get("nmr_verified", False),
        "is_active":    p.get("is_active", False),
        "disabled":     p.get("disabled", False),

        # Display
        "image_url":        p.get("image_url", ""),
        "experience_years": p.get("experience_years", 0),
        "rating":           p.get("rating", 5.0),
        "is_online":        p.get("is_online", False),
        "can_connect_now":  p.get("can_connect_now", True),

        "created_at": p["created_at"].isoformat() if hasattr(p.get("created_at"), "isoformat") else str(p.get("created_at", "")),
    }