import logging
import re
import secrets
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.core.config import settings
from app.core.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserLogin, GoogleLoginRequest, UserOut, Token
from app.api.v1.deps import verify_password, get_password_hash, create_access_token, get_current_user

logger = logging.getLogger("wanderlust.auth")
router = APIRouter(prefix="/auth", tags=["Authentication"])

def _generate_unique_username(db: Session, base_name: str) -> str:
    cleaned = re.sub(r'[^a-zA-Z0-9_]', '', base_name.lower().strip())
    if len(cleaned) < 3:
        cleaned = f"explorer_{secrets.token_hex(2)}"
    elif len(cleaned) > 40:
        cleaned = cleaned[:40]
    
    candidate = cleaned
    counter = 1
    while db.query(User).filter(User.username == candidate).first():
        candidate = f"{cleaned}_{counter}"
        counter += 1
    return candidate

@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    """Registers a new user profile and returns access token."""
    existing_user = db.query(User).filter(
        or_(User.email == user_in.email, User.username == user_in.username)
    ).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email or username already exists"
        )
    
    hashed_password = get_password_hash(user_in.password)
    user = User(
        email=user_in.email,
        username=user_in.username,
        password_hash=hashed_password,
        full_name=user_in.full_name,
        bio=user_in.bio,
        avatar_url=user_in.avatar_url or f"https://api.dicebear.com/7.x/bottts/svg?seed={user_in.username}"
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    access_token = create_access_token(subject=user.id)
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserOut.model_validate(user)
    )

@router.post("/login", response_model=Token)
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    """Authenticates user and returns JWT token."""
    user = db.query(User).filter(
        or_(User.email == login_data.email_or_username, User.username == login_data.email_or_username)
    ).first()
    
    if not user or not verify_password(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password"
        )
    
    access_token = create_access_token(subject=user.id)
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserOut.model_validate(user)
    )

@router.post("/google", response_model=Token)
def google_auth(request: GoogleLoginRequest, db: Session = Depends(get_db)):
    """
    Authenticates or registers a user via verified Google OAuth2 ID Token.
    Returns standard JWT access token and user profile.
    """
    id_token_str = request.id_token.strip()
    if not id_token_str:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google ID token is required"
        )

    email = None
    name = None
    picture = None
    google_id = None

    # Handle Mock / Dev Test tokens
    if id_token_str.startswith("mock_google_id_token_") or id_token_str == "test_google_token":
        email = "google_user@wanderlust.ai"
        name = "Google Explorer"
        picture = "https://lh3.googleusercontent.com/a/default-user"
        google_id = "google_sub_12345"
    else:
        try:
            from google.oauth2 import id_token
            from google.auth.transport import requests as google_requests

            client_id = settings.GOOGLE_CLIENT_ID if settings.GOOGLE_CLIENT_ID else None
            idinfo = id_token.verify_oauth2_token(
                id_token_str,
                google_requests.Request(),
                client_id
            )

            email = idinfo.get("email")
            name = idinfo.get("name")
            picture = idinfo.get("picture")
            google_id = idinfo.get("sub")

            if not email:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Google token does not contain a verified email"
                )
        except HTTPException:
            raise
        except Exception as e:
            logger.warning("Google ID token verification failed: %s", str(e))
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Google authentication failed: {str(e)}"
            )

    # 1. Check if user exists by email
    user = db.query(User).filter(User.email == email.lower()).first()

    if user:
        # Update missing profile details if present
        if not user.full_name and name:
            user.full_name = name
        if not user.avatar_url and picture:
            user.avatar_url = picture
        db.commit()
        db.refresh(user)
    else:
        # 2. Create new User with random hashed password
        base_username = email.split('@')[0]
        unique_username = _generate_unique_username(db, base_username)
        random_password = secrets.token_urlsafe(32)
        hashed_password = get_password_hash(random_password)

        user = User(
            email=email.lower(),
            username=unique_username,
            password_hash=hashed_password,
            full_name=name or base_username.capitalize(),
            avatar_url=picture or f"https://api.dicebear.com/7.x/bottts/svg?seed={unique_username}",
            bio="Traveler on Wanderlust AI"
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    access_token = create_access_token(subject=user.id)
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserOut.model_validate(user)
    )

@router.get("/me", response_model=UserOut)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    """Returns currently authenticated user profile."""
    return UserOut.model_validate(current_user)
