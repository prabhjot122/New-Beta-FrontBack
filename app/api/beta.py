"""
Beta User Registration API
=========================
Handles beta user registration for the LawVriksh platform.
This endpoint is specifically for the beta joining page where users
enter only their name and email.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr, constr
from app.core.dependencies import get_db
from app.models.user import User
from app.services.user_service import get_user_by_email
from passlib.context import CryptContext
import secrets
import string
from datetime import datetime
import logging

# Setup logging
logger = logging.getLogger(__name__)

# Router setup
router = APIRouter(prefix="/beta", tags=["beta"])

# Password context for hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class BetaUserCreate(BaseModel):
    """Schema for beta user registration (name + email only)"""
    name: constr(min_length=1, max_length=100)
    email: EmailStr

class BetaUserResponse(BaseModel):
    """Response schema for beta user registration"""
    user_id: int
    name: str
    email: EmailStr
    created_at: datetime
    is_beta_user: bool = True
    message: str

    class Config:
        from_attributes = True

def generate_temp_password(length: int = 16) -> str:
    """Generate a temporary password for beta users"""
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(secrets.choice(alphabet) for _ in range(length))

@router.post("/signup", response_model=BetaUserResponse, status_code=201)
def beta_signup(user_data: BetaUserCreate, db: Session = Depends(get_db)):
    """
    Register a beta user with just name and email.
    
    This endpoint is specifically designed for the beta joining page
    where users only provide their name and email. A temporary password
    is generated automatically.
    
    Args:
        user_data: Beta user data (name and email)
        db: Database session
        
    Returns:
        BetaUserResponse: Created beta user information
        
    Raises:
        HTTPException: If email is already registered or creation fails
    """
    try:
        logger.info(f"Beta signup attempt for email: {user_data.email}")
        
        # Check if user already exists
        existing_user = get_user_by_email(db, user_data.email)
        if existing_user:
            logger.warning(f"Beta signup failed - email already registered: {user_data.email}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered. If you're already a member, please use the login page."
            )
        
        # Generate a temporary password for the beta user
        temp_password = generate_temp_password()
        password_hash = pwd_context.hash(temp_password)
        
        # Create beta user
        beta_user = User(
            name=user_data.name.strip(),
            email=user_data.email.lower().strip(),
            password_hash=password_hash,
            is_active=True,
            is_admin=False,
            total_points=0,
            shares_count=0
        )
        
        # Add to database
        db.add(beta_user)
        db.commit()
        db.refresh(beta_user)
        
        logger.info(f"Beta user created successfully: {beta_user.email} (ID: {beta_user.id})")
        
        # Schedule welcome email (if email service is available)
        try:
            from app.tasks.email_tasks import send_beta_welcome_email_task
            send_beta_welcome_email_task.delay(
                user_email=beta_user.email,
                user_name=beta_user.name,
                temp_password=temp_password
            )
            logger.info(f"Beta welcome email scheduled for: {beta_user.email}")
        except Exception as email_error:
            logger.warning(f"Failed to schedule beta welcome email: {email_error}")
            # Don't fail the registration if email fails
        
        # Update metrics
        try:
            from app.utils.monitoring import inc_user_signup
            inc_user_signup()
        except Exception as metrics_error:
            logger.warning(f"Failed to update signup metrics: {metrics_error}")
        
        return BetaUserResponse(
            user_id=beta_user.id,
            name=beta_user.name,
            email=beta_user.email,
            created_at=beta_user.created_at,
            is_beta_user=True,
            message="Welcome to LawVriksh Beta! Check your email for login credentials."
        )
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Beta signup failed for {user_data.email}: {str(e)}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create beta user account. Please try again later."
        )

@router.get("/stats")
def get_beta_stats(db: Session = Depends(get_db)):
    """
    Get beta user statistics.
    
    Returns:
        dict: Beta user statistics
    """
    try:
        # Count total beta users (users created through beta signup)
        total_users = db.query(User).filter(User.is_admin == False).count()
        
        # Count users created in the last 24 hours
        from datetime import datetime, timedelta
        yesterday = datetime.utcnow() - timedelta(days=1)
        recent_users = db.query(User).filter(
            User.is_admin == False,
            User.created_at >= yesterday
        ).count()
        
        # Count users created in the last week
        last_week = datetime.utcnow() - timedelta(days=7)
        weekly_users = db.query(User).filter(
            User.is_admin == False,
            User.created_at >= last_week
        ).count()
        
        return {
            "total_beta_users": total_users,
            "users_last_24h": recent_users,
            "users_last_week": weekly_users,
            "status": "active"
        }
        
    except Exception as e:
        logger.error(f"Failed to get beta stats: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve beta statistics"
        )

@router.get("/health")
def beta_health_check():
    """Health check endpoint for beta registration service"""
    return {
        "status": "healthy",
        "service": "beta_registration",
        "timestamp": datetime.utcnow().isoformat()
    }
