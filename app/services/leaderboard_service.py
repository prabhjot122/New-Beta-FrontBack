import logging
from sqlalchemy.orm import Session
from app.models.user import User
from app.utils.cache import get_leaderboard_cache, set_leaderboard_cache
from typing import List

def get_leaderboard(db: Session, page: int = 1, limit: int = 50):
    """Get leaderboard, using cache for efficiency."""
    try:
        cached = get_leaderboard_cache(page, limit)
        if cached:
            logging.info(f"Leaderboard cache hit for page {page}, limit {limit}")
            return cached
        logging.info(f"Leaderboard cache miss for page {page}, limit {limit}")
    except Exception as e:
        logging.error(f"Leaderboard cache error: {e}")
        cached = None
    # Get users ordered by points (desc) then by created_at (asc) for consistent ranking
    users = db.query(User).filter(
        User.is_admin == False
    ).order_by(
        User.total_points.desc(),
        User.created_at.asc()
    ).offset((page-1)*limit).limit(limit).all()

    leaderboard = []
    for idx, u in enumerate(users):
        # Calculate actual rank based on position in sorted list
        actual_rank = idx + 1 + (page - 1) * limit

        # Calculate rank improvement
        rank_improvement = 0
        if u.default_rank and u.current_rank:
            rank_improvement = u.default_rank - u.current_rank
        elif u.default_rank:
            rank_improvement = u.default_rank - actual_rank

        leaderboard.append({
            "rank": actual_rank,
            "user_id": u.id,
            "name": u.name,
            "points": u.total_points,
            "shares_count": u.shares_count,
            "badge": None,
            "default_rank": u.default_rank,
            "rank_improvement": rank_improvement
        })
    try:
        set_leaderboard_cache(leaderboard, page, limit)
    except Exception as e:
        logging.error(f"Leaderboard cache set error: {e}")
    return leaderboard

def get_user_rank(db: Session, user_id: int):
    """Get the current rank of a user by user_id."""
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if user:
            return user.current_rank
        return None
    except Exception as e:
        logging.error(f"Error getting user rank for user_id {user_id}: {e}")
        return None