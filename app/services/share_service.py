from sqlalchemy.orm import Session
from app.models.share import ShareEvent, PlatformEnum
from app.models.user import User
from app.utils.cache import invalidate_leaderboard_cache
from fastapi import HTTPException, status
from datetime import datetime

PLATFORM_POINTS = {
    PlatformEnum.twitter: 1,
    PlatformEnum.instagram: 2,
    PlatformEnum.linkedin: 5,
    PlatformEnum.facebook: 3,
    PlatformEnum.whatsapp: 2
}

def log_share_event(db: Session, user_id: int, platform: PlatformEnum):
    """
    Award points only for the first share on each platform.
    Twitter=+1, Instagram=+2, LinkedIn=+5, Facebook=+3.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if user has already shared on this platform
    already_shared = db.query(ShareEvent).filter(
        ShareEvent.user_id == user_id,
        ShareEvent.platform == platform
    ).first()

    if already_shared:
        return None, user, 0

    points = PLATFORM_POINTS[platform]
    share = ShareEvent(
        user_id=user.id,
        platform=platform,
        points_earned=points
        # Let database handle created_at with DEFAULT CURRENT_TIMESTAMP
    )

    try:
        # Update user points and shares
        user.total_points += points
        user.shares_count += 1
        db.add(share)
        db.commit()
        db.refresh(share)
        db.refresh(user)

        # Update user's dynamic rank after earning points
        from app.services.ranking_service import update_user_rank
        new_rank = update_user_rank(db, user.id)

        # Refresh user to get updated rank
        db.refresh(user)

        invalidate_leaderboard_cache()
        return share, user, points
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to record share event")