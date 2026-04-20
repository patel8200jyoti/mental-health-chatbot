"""
Endpoints:
  POST  /mood/           – log or update today's mood
  GET   /mood/week       – last 7 days (backward compat)
  GET   /mood/all        – full history, sorted oldest→newest
  GET   /mood/stats      – aggregated daily / weekly / monthly averages
  GET   /mood/streak     – current consecutive-day streak
"""

from fastapi import APIRouter, Depends, HTTPException
from models.mood_check import MoodCreate, MoodResponse
from services.mood_service import (
    calculate_streak,
    create_mood,
    get_all_moods,
    get_mood_stats,
    get_week_moods,
)
from routes.auth import get_current_user
import logging

logger = logging.getLogger(__name__)

app = APIRouter(prefix="/mood", tags=["Mood"])


@app.post("/", response_model=MoodResponse)
async def add_mood(mood: MoodCreate, user=Depends(get_current_user)):
    logger.info(f"Received mood payload: {mood.model_dump()}")
    new_mood = await create_mood(mood, user)
    if not new_mood:
        raise HTTPException(status_code=400, detail="Mood already added for today")
    return new_mood


@app.get("/week")
async def week_mood(user=Depends(get_current_user)):
    """Last 7 days — kept for backward compatibility."""
    logger.info("Fetching moods for the past week")
    return await get_week_moods(user)


@app.get("/all")
async def all_moods(user=Depends(get_current_user)):
    """Full mood history for the user, sorted oldest → newest."""
    logger.info("Fetching all moods for user")
    return await get_all_moods(user)


@app.get("/stats")
async def mood_stats(user=Depends(get_current_user)):
    """
    Pre-aggregated averages for the graph.
    Returns:  { daily: [...], weekly: [...], monthly: [...] }
    """
    logger.info("Fetching mood stats for user")
    return await get_mood_stats(user)


@app.get("/streak")
async def streak(user=Depends(get_current_user)):
    logger.info("Calculating mood streak")
    return await calculate_streak(user)