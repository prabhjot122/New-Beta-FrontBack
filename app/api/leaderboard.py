from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.core.dependencies import get_db
from app.schemas.leaderboard import LeaderboardResponse, LeaderboardUser, AroundMeResponse, AroundMeUser, TopPerformersResponse, TopPerformer
from app.services.leaderboard_service import get_leaderboard, get_user_rank
from app.core.security import verify_access_token
from fastapi.security import OAuth2PasswordBearer
from app.models.user import User
from typing import List

router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

@router.get("", response_model=LeaderboardResponse)
def leaderboard(page: int = Query(1, ge=1), limit: int = Query(50, ge=1, le=100), db: Session = Depends(get_db)):
    """
    Get public leaderboard with pagination.

    This is a public endpoint that doesn't require authentication.

    Args:
        page: Page number (starts from 1)
        limit: Number of users per page (max 100)
        db: Database session

    Returns:
        LeaderboardResponse: Paginated leaderboard data
    """
    try:
        # Get leaderboard data
        leaderboard_data = get_leaderboard(db, page, limit)
        total_users = db.query(User).count()
        total_pages = (total_users + limit - 1) // limit

        return LeaderboardResponse(
            leaderboard=[LeaderboardUser(**u) for u in leaderboard_data],
            pagination={
                "page": page,
                "limit": limit,
                "total": total_users,
                "pages": total_pages
            },
            metadata={
                "total_users": total_users,
                "your_rank": None,  # No user context for public endpoint
                "your_points": 0    # No user context for public endpoint
            }
        )

    except Exception as e:
        import logging
        logging.getLogger(__name__).error(f"Leaderboard failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve leaderboard"
        )

@router.get("/around-me", response_model=AroundMeResponse)
def leaderboard_around_me(range: int = 5, db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)):
    payload = verify_access_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")
    users = db.query(User).order_by(User.total_points.desc()).all()
    user_rank = get_user_rank(db, payload["user_id"])
    idx = user_rank - 1 if user_rank else 0
    start = max(0, idx - range)
    end = min(len(users), idx + range + 1)
    surrounding = [AroundMeUser(rank=i+1, name=u.name, points=u.total_points, is_current_user=(u.id==payload["user_id"])) for i, u in enumerate(users[start:end], start=start)]
    user = db.query(User).filter(User.id == payload["user_id"]).first()
    return AroundMeResponse(
        surrounding_users=surrounding,
        your_stats={
            "rank": user_rank,
            "points": user.total_points if user else 0,
            "points_to_next_rank": users[idx-1].total_points - user.total_points if idx > 0 else 0,
            "percentile": 100.0 * (1 - (user_rank-1)/len(users)) if user_rank else 0
        }
    )

@router.get("/top-performers", response_model=TopPerformersResponse)
def leaderboard_top_performers(
    period: str = Query("weekly", regex="^(daily|weekly|monthly|all-time)$"),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """
    Get top performers for a specific period.

    This is a public endpoint that shows top performing users.

    Args:
        period: Time period (daily, weekly, monthly, all-time)
        limit: Number of top performers to return (max 50)
        db: Database session

    Returns:
        TopPerformersResponse: Top performers data
    """
    try:
        # For now, just return top N users (period logic can be added later)
        users = db.query(User).order_by(User.total_points.desc()).limit(limit).all()

        top_performers = []
        for i, u in enumerate(users):
            top_performers.append(TopPerformer(
                rank=i+1,
                user_id=u.id,
                name=u.name,
                points_gained=u.total_points,  # For now, same as total points
                total_points=u.total_points,
                growth_rate="0%"  # Placeholder for future implementation
            ))

        total_points = sum(u.total_points for u in users) if users else 0

        return TopPerformersResponse(
            period=period,
            top_performers=top_performers,
            period_stats={
                "start_date": "",
                "end_date": "",
                "total_points_awarded": total_points,
                "active_users": len(users)
            }
        )

    except Exception as e:
        import logging
        logging.getLogger(__name__).error(f"Top performers failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve top performers"
        )