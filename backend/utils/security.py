from datetime import datetime, timedelta
from typing import Optional
from passlib.context import CryptContext
from jose import jwt, JWTError
from config import settings

SECRET_KEY   = settings.SECRET_KEY
ALGORITHM    = settings.ALGORITHM
ACCESS_TOKEN = settings.ACCESS_TOKEN_EXPIRE_HOURS

# ── Password context ──────────────────────────────────────────────────────────
# argon2 is the primary scheme (new registrations).
# bcrypt is kept as a deprecated fallback so OLD users who registered when
# bcrypt was the scheme can still log in. passlib will auto-identify which
# scheme a stored hash uses and verify correctly for both.
pwd = CryptContext(
    schemes=["argon2", "bcrypt"],
    deprecated="auto",          # marks bcrypt as deprecated but still verifiable
)


def hash_password(password: str) -> str:
    """Hash with argon2 (current default scheme)."""
    return pwd.hash(password)


# converting hash password
def verify_password(plain_pass: str, hash_pass: str) -> bool:
    """
    Verify plain password against stored hash.
    Works for BOTH argon2 and bcrypt hashes — passlib auto-identifies the scheme.
    Returns False (instead of raising) if the hash is completely unrecognised.
    """
    try:
        return pwd.verify(plain_pass, hash_pass)
    except Exception:
        return False



#  token create
# data - role,email /convert 
def create_access_token(data: dict, expire_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (
        expire_delta if expire_delta else timedelta(hours=ACCESS_TOKEN)
    )
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


# converting
def verify_token(token: str) -> Optional[str]:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        return email if email else None
    except JWTError:
        return None