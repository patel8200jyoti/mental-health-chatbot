from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import date

class ProfessionalRegisterRequest(BaseModel):
    full_name: str
    medical_registration_number: str
    state_medical_council: str
    year_of_registration: str
    educational_qualifications: str
    user_email: EmailStr
    password: str
    user_dob: Optional[date] = None
    user_gender: Optional[str] = None


class LinkRequest(BaseModel):
    professional_id: str


class ProfessionalNote(BaseModel):
    note: str