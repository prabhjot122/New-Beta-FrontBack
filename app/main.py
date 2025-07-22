import os
import logging
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, users, shares, leaderboard, admin, campaigns, feedback
from app.utils.monitoring import prometheus_middleware, prometheus_endpoint
from app.core.error_handlers import setup_error_handlers, RateLimitError
from app.core.config import settings
import time
from collections import defaultdict

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI app with enhanced metadata
app = FastAPI(
    title="Lawvriksh Referral Platform API",
    description="A comprehensive referral platform for legal services with social sharing and gamification",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Setup error handlers
setup_error_handlers(app)

# Simple in-memory rate limiter (per-IP, per-minute)
RATE_LIMIT = 60  # requests per minute
rate_limit_store = defaultdict(list)

@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    """
    Rate limiting middleware to prevent abuse.
    Limits requests per IP address per minute.
    """
    # Skip rate limiting during testing
    if os.getenv("TESTING") == "true":
        return await call_next(request)

    # Skip rate limiting for health checks and metrics
    if request.url.path in ["/health", "/metrics", "/docs", "/redoc", "/openapi.json"]:
        return await call_next(request)

    try:
        # Get client IP address
        ip = request.client.host if request.client else "unknown"
        if ip == "unknown":
            # Try to get IP from headers (for reverse proxy setups)
            ip = request.headers.get("X-Forwarded-For", "unknown")
            if "," in ip:
                ip = ip.split(",")[0].strip()

        now = time.time()
        window = 60  # seconds

        # Clean up old requests outside the time window
        rate_limit_store[ip] = [t for t in rate_limit_store[ip] if now - t < window]

        # Check if rate limit exceeded
        if len(rate_limit_store[ip]) >= RATE_LIMIT:
            logger.warning(f"Rate limit exceeded for IP: {ip}")
            raise RateLimitError(f"Rate limit exceeded. Maximum {RATE_LIMIT} requests per minute allowed.")

        # Record this request
        rate_limit_store[ip].append(now)

        # Add rate limit headers to response
        response = await call_next(request)
        remaining = max(0, RATE_LIMIT - len(rate_limit_store[ip]))
        response.headers["X-RateLimit-Limit"] = str(RATE_LIMIT)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        response.headers["X-RateLimit-Reset"] = str(int(now + window))

        return response

    except RateLimitError:
        # Re-raise rate limit errors to be handled by error handler
        raise
    except Exception as e:
        # Log error but don't block the request
        logger.error(f"Rate limiting middleware error: {e}")
        return await call_next(request)

# CORS setup (customize origins as needed)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        settings.FRONTEND_URL,
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:3001",  # Add support for port 3001
        "http://127.0.0.1:3001"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus monitoring middleware
prometheus_middleware(app)

# Routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(shares.router)
app.include_router(leaderboard.router)
app.include_router(admin.router)
app.include_router(campaigns.router)
app.include_router(feedback.router)

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/metrics")
def metrics():
    return prometheus_endpoint() 