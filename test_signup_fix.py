#!/usr/bin/env python3
"""
Test script to verify database schema and signup functionality
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from app.core.config import settings
from app.models.user import User
from app.services.user_service import create_user
from app.schemas.user import UserCreate
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_database_connection():
    """Test basic database connection"""
    try:
        engine = create_engine(settings.database_url)
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1 as test"))
            logger.info("✅ Database connection successful")
            return True
    except Exception as e:
        logger.error(f"❌ Database connection failed: {e}")
        return False

def test_table_structure():
    """Test if all required tables exist with correct structure"""
    try:
        engine = create_engine(settings.database_url)
        with engine.connect() as conn:
            # Check users table
            result = conn.execute(text("DESCRIBE users"))
            users_columns = [row[0] for row in result]
            logger.info(f"Users table columns: {users_columns}")
            
            # Check share_events table
            result = conn.execute(text("DESCRIBE share_events"))
            share_columns = [row[0] for row in result]
            logger.info(f"Share_events table columns: {share_columns}")
            
            # Check feedback table
            result = conn.execute(text("DESCRIBE feedback"))
            feedback_columns = [row[0] for row in result]
            logger.info(f"Feedback table columns: {feedback_columns}")
            
            # Verify required columns exist
            required_user_columns = ['id', 'name', 'email', 'password_hash', 'total_points', 
                                   'shares_count', 'default_rank', 'current_rank', 'is_active', 
                                   'is_admin', 'created_at', 'updated_at']
            
            missing_columns = [col for col in required_user_columns if col not in users_columns]
            if missing_columns:
                logger.error(f"❌ Missing columns in users table: {missing_columns}")
                return False
            
            logger.info("✅ All required table columns exist")
            return True
            
    except Exception as e:
        logger.error(f"❌ Table structure check failed: {e}")
        return False

def test_user_creation():
    """Test user creation functionality"""
    try:
        engine = create_engine(settings.database_url)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        # Create test user data
        test_user = UserCreate(
            name="Test User",
            email=f"test_{int(__import__('time').time())}@example.com",
            password="testpass123"
        )
        
        # Try to create user
        user = create_user(db, test_user)
        logger.info(f"✅ User created successfully: ID={user.id}, Name={user.name}")
        
        # Clean up - delete test user
        db.delete(user)
        db.commit()
        db.close()
        
        return True
        
    except Exception as e:
        logger.error(f"❌ User creation failed: {e}")
        if 'db' in locals():
            db.rollback()
            db.close()
        return False

def main():
    """Run all tests"""
    logger.info("🔧 Testing LawVriksh Database Schema and Signup")
    logger.info("=" * 50)
    
    # Test 1: Database connection
    logger.info("Test 1: Database Connection")
    if not test_database_connection():
        logger.error("Database connection failed. Please check your .env file and MySQL server.")
        return False
    
    # Test 2: Table structure
    logger.info("\nTest 2: Table Structure")
    if not test_table_structure():
        logger.error("Table structure is incorrect. Please run the updated lawdata.sql file.")
        return False
    
    # Test 3: User creation
    logger.info("\nTest 3: User Creation")
    if not test_user_creation():
        logger.error("User creation failed. Check the error details above.")
        return False
    
    logger.info("\n🎉 All tests passed! Your database is ready for signup.")
    logger.info("You can now test the frontend signup functionality.")
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
