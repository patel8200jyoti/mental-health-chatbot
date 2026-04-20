from motor.motor_asyncio import AsyncIOMotorClient
from config import settings
import logging


mongo = settings.MONGODB_URL

logger = logging.getLogger(__name__)

class Database :
    client : AsyncIOMotorClient | None = None

db= Database()

async def get_database():
    if not db.client:
        raise Exception("MongoDB client is not initialized. Call connect_to_mongo() first.")
    return db.client[settings.DATABASE_NAME]


async def connect_to_mongo():
    db.client = AsyncIOMotorClient(mongo)
    logger.info("Mongooo connectedddddd")
    

async def close_mongo():
    if db.client:
        db.client.close()
        logger.info("mongo closed bye byeeeeee")

