from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from datetime import timedelta, datetime

from schemas.user import user_schema
from config import settings
from models.user_chcek import UserCreate, UserLogin, Token
from utils.security import hash_password, verify_password, create_access_token, verify_token
from services.auth_service import get_user, create_user
from database import get_database

from uuid import uuid4
import logging

logger = logging.getLogger(__name__)
ACCESS_TOKEN_EXPIRE_HOURS = settings.ACCESS_TOKEN_EXPIRE_HOURS


app = APIRouter(prefix='/auth', tags=['Auth'])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl='/auth/login')




async def authenticate_user(user_email: str, password: str):
    """
    Authenticate by email — works for both regular users AND professionals
    since both store user_email.
    """
    # Always query by email, never by user_name
    db = await get_database()
    user = await db.users.find_one({"user_email": user_email})

    if not user:
        logger.info(f'No user found for email: {user_email}')
        return False

    # BUG FIX: default must be False — professionals may not have disabled field
    if user.get('disabled', False):
        logger.info('User is disabled')
        return False

    if not verify_password(password, user['password']):
        logger.info('Password not matched')
        return False

    return user_schema(user)




async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail='Could not validate credentials',
        headers={'WWW-Authenticate': 'Bearer'}
    )

    # verify_token returns the 'sub' value = user_email
    user_email = verify_token(token)
    if user_email is None:
        logger.info("Email not found in token")
        raise credentials_exception

    # Query by email directly — do NOT go through get_user() if it uses user_name
    db = await get_database()
    user = await db.users.find_one({"user_email": user_email})
    if user is None:
        logger.info(f"User not found for email: {user_email}")
        raise credentials_exception

    return user_schema(user)


# ── Routes ────────────────────────────────────────────────────────────────────

@app.post("/register")
async def register(user: UserCreate):
    db = await get_database()
    existing_user = await db.users.find_one({"user_email": user.user_email})
    if existing_user:
        raise HTTPException(status_code=400, detail='Email already registered.')

    new_user = await create_user(user)
    logger.info("User created successfully")
    return new_user




@app.post("/login")
async def login(data: OAuth2PasswordRequestForm = Depends()):
    # data.username holds the email (Flutter sends email in the username field)
    user = await authenticate_user(data.username, data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='Incorrect email or password',
            headers={'WWW-Authenticate': 'Bearer'},
        )

    access_token_expire = timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS)
    access_token = create_access_token(
        data={'sub': user['user_email'], 'role': user.get('role', 'user')},
        expire_delta=access_token_expire,
    )
    logger.info(f"User logged in: {user['user_email']} role={user.get('role')}")
    return {'access_token': access_token, 'token_type': 'bearer'}