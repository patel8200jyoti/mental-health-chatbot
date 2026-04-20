from fastapi import FastAPI

from routes.auth import app as user_router
from routes.chat import app as chat_router
from routes.mood import app as mood_router
from routes.journal import app as journal_router
from routes.toolkit import app as toolkit_router
from routes.admin import app as admin_router
from routes.professional import app as professional_router
from routes.profile import router as profile_router
from routes.user_proff import app as user_proff_router
from database import connect_to_mongo,close_mongo

from fastapi.middleware.cors import CORSMiddleware

import logging
import sys


logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s | %(levelname)s | %(name)s | %(message)s',
    handlers=[ logging.StreamHandler(sys.stdout)]
)
app=FastAPI()


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        
    allow_credentials=False,   
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_db():
    await connect_to_mongo()

@app.on_event("shutdown")
async def shutdown_db():
    await close_mongo()



@app.get('/')
def root():
    return {'message': 'Mental Health Chatbot is running'}

# User login router 
app.include_router(user_router)
app.include_router(chat_router)
app.include_router(mood_router)
app.include_router(journal_router)
app.include_router(toolkit_router)
app.include_router(admin_router)
app.include_router(professional_router)
app.include_router(profile_router)
app.include_router(user_proff_router)

