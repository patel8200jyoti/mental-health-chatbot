"""
Endpoints:
GET     /profile/me
Put     /profile/me
GET     /profile/report/me
POST    /profile/report/me
POST    /logout

"""
from fastapi import APIRouter, HTTPException, Header, Depends
from routes.auth import get_current_user
from services.profile_service import (
    get_user_profile,
    update_user_profile,
    get_report,
    generate_report,
)
from models.user_chcek import UserOut, UserUpdate, ReportOut

router = APIRouter(prefix="/profile", tags=["Profile"])

# In-memory token blacklist (replace with Redis in production)
_blacklisted_tokens: set[str] = set()


async def blacklist_token(token: str):
    _blacklisted_tokens.add(token)


@router.get("/me", response_model=UserOut)
async def fetch_profile(user=Depends(get_current_user)):
    user_data = await get_user_profile(user["user_id"])
    if not user_data:
        raise HTTPException(status_code=404, detail="User not found")
    return user_data

@router.put("/me", response_model=UserOut)
async def update_profile(profile: UserUpdate, user=Depends(get_current_user)):
    updated = await update_user_profile(user, profile.model_dump(exclude_unset=True))
    if not updated:
        raise HTTPException(status_code=404, detail="User not found")
    return updated


@router.get("/report/me", response_model=ReportOut)
async def view_report(user=Depends(get_current_user)):
    report = await get_report(user["user_id"])
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    return {
        "report_text": report["report_text"],
        "generated_at": report["generated_at"].isoformat()
        if hasattr(report["generated_at"], "isoformat")
        else report["generated_at"],
    }


@router.post("/report/me", response_model=ReportOut)
async def regenerate_report(user=Depends(get_current_user)):
    report = await generate_report(user["user_id"])
    if not report:
        raise HTTPException(status_code=500, detail="Report could not be generated")
    return {
        "report_text": report["report_text"],
        "generated_at": report["generated_at"].isoformat()
        if hasattr(report["generated_at"], "isoformat")
        else report["generated_at"],
    }


@router.post("/logout")
async def logout(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    await blacklist_token(token)
    return {"message": "Logged out successfully"}