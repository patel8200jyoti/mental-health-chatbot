from fastapi import APIRouter,Depends
from models.journal import JournalCreate,JournalResponse
from services.journal_service import(
    create_journal,
    fetch_journal,
    update_journal as update_journal_service,
    delete_journal as delete_journal_service
    ) 
from routes.auth import get_current_user
import logging
logger = logging.getLogger(__name__)



app = APIRouter(prefix="/journal", tags=["Journal"])


@app.get("/", response_model=list[JournalResponse])
async def get_journals(user=Depends(get_current_user)):       
    return await fetch_journal(user)

@app.post("/", response_model=JournalResponse)
async def add_journal(journal: JournalCreate, user=Depends(get_current_user)):
    return await create_journal(journal, user)

@app.put("/{journal_id}")
async def edit_journal(journal_id: str, journal: JournalCreate, user=Depends(get_current_user)):
    return await update_journal_service(journal_id, journal, user)

@app.delete("/{journal_id}")
async def remove_journal(journal_id: str, user=Depends(get_current_user)):
    return await delete_journal_service(journal_id, user)