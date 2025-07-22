from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
from app.core.config import settings
from diskcache import Cache

engine = create_engine(settings.database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

cache = Cache(settings.CACHE_DIR)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_cache():
    return cache 