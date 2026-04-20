"""
Data Validation for user activity

UserCreate -            user creation 
UserLogin -             user login data 
UserResponse -          user response 
Token -                 token creation required fields
UserUpdate -            user update 
UserOut -               for the profile screen user data
ReportOut -             fields for the report 
"""


from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, Literal, Annotated
from datetime import date, datetime


class UserCreate(BaseModel):
    user_email: Annotated[EmailStr, Field(...)]
    password: Annotated[str, Field(..., min_length=6, max_length=15)]
    user_name: Annotated[str, Field(...)]
    user_dob: Annotated[Optional[date], Field(default=None)]
    user_gender: Annotated[Optional[Literal['Male', 'Female', 'Other']], Field(default=None)]

    @field_validator('user_dob')
    def birthdate_no_future(cls, v: date) -> date:
        if v is None:
            return v
        if v > date.today():
            raise ValueError("Birthdate cannot be in future")
        age = (date.today() - v).days // 365
        if age < 10:
            raise ValueError("You must be at least 10 years old")
        return v

    @field_validator('password')
    def validate_password(cls, v: str) -> str:
        if not any(char.isdigit() for char in v):
            raise ValueError('Password must contain at least a digit')
        if not any(char.isupper() for char in v):
            raise ValueError('Password must have at least one capital letter')
        if not any(char.islower() for char in v):
            raise ValueError('Password must have one lowercase letter')
        return v


class UserLogin(BaseModel):
    user_email: Annotated[EmailStr, Field(...)]
    password: Annotated[str, Field(..., min_length=6, max_length=15)]


class UserResponse(BaseModel):
    id: str
    user_email: str
    user_name: str
    user_dob: Optional[date]
    user_gender: Optional[Literal['Male', 'Female', 'Other']]
    disabled: bool = False
    created_at: datetime
    role: str


class Token(BaseModel):
    access_token: str
    token_type: str = 'bearer'


class UserUpdate(BaseModel):
    # Match Flutter's ApiService.updateProfile call fields
    user_name: Optional[str] = None
    user_email: Optional[str] = None
    user_gender: Optional[str] = None
    user_dob: Optional[str] = None


class UserOut(BaseModel):
    """
    Maps MongoDB document fields → Flutter-friendly response.
    MongoDB stores: user_name, user_email, user_dob, user_gender
    Flutter PersonalInformationScreen reads: fullName, email, dateOfBirth, gender
    We expose them with clear names and aliases.
    """
    id: str
    user_name: str          # Flutter reads this as fullName
    user_email: str         # Flutter reads this as email
    user_gender: Optional[str] = None
    user_dob: Optional[str] = None
    disabled: bool = False
    created_at: Optional[str] = None
    updated_at: Optional[str] = None

    model_config = {"populate_by_name": True}


class ReportOut(BaseModel):
    report_text: str
    generated_at: str