from database import get_database
from models.user_chcek import UserCreate
from schemas.user import user_entity,user_schema

import logging
logger = logging.getLogger(__name__)
# db =   get_database()



async def get_user(email : str):
    '''
    Fetch the user from the database 
    
    :param email: email of the user 
    :type email: str
    '''
    
    db = await get_database()
    user = await db.users.find_one({'user_email' : email})
    if user is None:
        logger.info("User not found in db")
        return None 
    return user



async def create_user(user : UserCreate):
    '''
    Insert new user in the database
    
    :param user: user data from the frontend
    :type user: UserCreate   [pydantic class]
    '''
    
    db = await get_database()
    existing_user = await db.users.find_one({'user_email': user.user_email})
    if existing_user :
        logger.info("User already exists in db")
        return None                 # user already exists 
    
    user_doc = user_entity(user.model_dump())
    result = await db.users.insert_one(user_doc)
    
    created_user = await db.users.find_one({"_id": result.inserted_id})
    
    return user_schema(created_user)
    
    

    