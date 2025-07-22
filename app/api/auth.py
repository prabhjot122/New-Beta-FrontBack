from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.dependencies import get_db
from app.schemas.user import UserCreate, UserLogin, UserResponse
from app.schemas.token import Token
from app.services.user_service import create_user, authenticate_user, create_jwt_for_user, get_user_by_email
from app.core.security import verify_access_token
from fastapi.security import OAuth2PasswordBearer
from app.tasks.email_tasks import send_delayed_welcome_email_task
from app.utils.monitoring import inc_user_signup

router = APIRouter(prefix="/auth", tags=["auth"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

@router.post("/signup", response_model=UserResponse, status_code=201)
def signup(user_in: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user account.

    Args:
        user_in: User registration data
        db: Database session

    Returns:
        UserResponse: Created user information

    Raises:
        HTTPException: If email is already registered or creation fails
    """
    # Check if user already exists
    existing_user = get_user_by_email(db, user_in.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    try:
        # Create new user
        user = create_user(db, user_in)

        # Send welcome email with 10-second delay to avoid frontend timeout
        try:
            # Try to schedule welcome email with Celery (with 10-second delay)
            try:
                send_delayed_welcome_email_task.apply_async(
                    args=[user.email, user.name],
                    countdown=10  # 10-second delay
                )
                import logging
                logging.getLogger(__name__).info(f"Welcome email scheduled for {user.email} in 10 seconds")
            except Exception as celery_error:
                # Fallback: Use threading to send email after 10 seconds if Celery is not available
                import threading
                import time
                import logging

                def delayed_email_sender():
                    time.sleep(10)  # Wait 10 seconds
                    try:
                        from app.services.email_campaign_service import send_welcome_email_campaign
                        send_welcome_email_campaign(user.email, user.name)
                        logging.getLogger(__name__).info(f"Delayed welcome email sent to {user.email} via threading fallback")
                    except Exception as email_error:
                        logging.getLogger(__name__).error(f"Failed to send delayed welcome email: {email_error}")

                # Start the delayed email in a separate thread
                email_thread = threading.Thread(target=delayed_email_sender, daemon=True)
                email_thread.start()

                logging.getLogger(__name__).warning(f"Celery not available ({celery_error}), using threading fallback for welcome email")

            # Log which campaigns are available for this new user
            from app.services.email_campaign_service import get_future_campaigns_for_new_user
            future_campaigns = get_future_campaigns_for_new_user()
            if future_campaigns:
                import logging
                logging.getLogger(__name__).info(
                    f"New user {user.email} will receive {len(future_campaigns)} future campaigns: {future_campaigns}"
                )
            else:
                import logging
                logging.getLogger(__name__).info(
                    f"New user {user.email} registered after all scheduled campaigns. Welcome email scheduled for 10 seconds."
                )

        except Exception as e:
            # Log email error but don't fail registration
            import logging
            logging.getLogger(__name__).warning(f"Failed to schedule welcome email: {e}")

        # Update metrics
        inc_user_signup()

        return UserResponse(
            user_id=user.id,
            name=user.name,
            email=user.email,
            created_at=user.created_at,
            total_points=user.total_points,
            shares_count=user.shares_count,
            default_rank=user.default_rank,
            current_rank=user.current_rank,
            is_admin=user.is_admin
        )

    except Exception as e:
        # Log the error and return a generic message
        import logging
        logging.getLogger(__name__).error(f"User creation failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create user account"
        )

@router.post("/login", response_model=Token)
def login(user_in: UserLogin, db: Session = Depends(get_db)):
    """
    Authenticate user and return access token.

    Args:
        user_in: User login credentials
        db: Database session

    Returns:
        Token: JWT access token with expiration info

    Raises:
        HTTPException: If credentials are invalid or user is inactive
    """
    try:
        # Authenticate user
        user = authenticate_user(db, user_in.email, user_in.password)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
                headers={"WWW-Authenticate": "Bearer"}
            )

        # Check if user is active
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is deactivated"
            )

        # Generate JWT token
        token = create_jwt_for_user(user)

        return Token(
            access_token=token,
            token_type="bearer",
            expires_in=3600
        )

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        # Log unexpected errors
        import logging
        logging.getLogger(__name__).error(f"Login failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Authentication service unavailable"
        )

@router.get("/me", response_model=UserResponse)
def get_me(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """
    Get current authenticated user information.

    Args:
        token: JWT access token
        db: Database session

    Returns:
        UserResponse: Current user information

    Raises:
        HTTPException: If token is invalid or user not found
    """
    try:
        # Verify and decode token
        payload = verify_access_token(token)
        if not payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token",
                headers={"WWW-Authenticate": "Bearer"}
            )

        # Get user from database
        user = get_user_by_email(db, payload["email"])
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User account not found"
            )

        # Check if user is still active
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is deactivated"
            )

        return UserResponse(
            user_id=user.id,
            name=user.name,
            email=user.email,
            created_at=user.created_at,
            total_points=user.total_points,
            shares_count=user.shares_count,
            default_rank=user.default_rank,
            current_rank=user.current_rank,
            is_admin=user.is_admin
        )

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        # Log unexpected errors
        import logging
        logging.getLogger(__name__).error(f"Get user info failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to retrieve user information"
        )