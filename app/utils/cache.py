import logging
from diskcache import Cache
from app.core.config import settings

cache = Cache(settings.CACHE_DIR, size_limit=int(2e9))  # 2GB limit

def get_leaderboard_cache(page: int = 1, limit: int = 50):
    """Get leaderboard data from cache."""
    try:
        cache_key = f"leaderboard:{page}:{limit}"
        return cache.get(cache_key)
    except Exception as e:
        logging.error(f"Cache get error: {e}")
        return None

def set_leaderboard_cache(data, page: int = 1, limit: int = 50, expire: int = 60):
    """Set leaderboard data in cache."""
    try:
        cache_key = f"leaderboard:{page}:{limit}"
        cache.set(cache_key, data, expire=expire)
    except Exception as e:
        logging.error(f"Cache set error: {e}")

def invalidate_leaderboard_cache():
    """Invalidate all leaderboard cache entries."""
    try:
        keys_to_delete = []
        for key in cache.iterkeys():
            if key.startswith('leaderboard:'):
                keys_to_delete.append(key)
        
        for key in keys_to_delete:
            cache.delete(key)
        
        logging.info(f"Invalidated {len(keys_to_delete)} leaderboard cache entries")
    except Exception as e:
        logging.error(f"Cache invalidation error: {e}") 