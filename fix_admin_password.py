#!/usr/bin/env python3
"""
Fix Admin Password Script
========================

This script will:
1. Generate correct bcrypt hashes for admin passwords
2. Update the admin user in the database
3. Verify the admin can login

Usage: python fix_admin_password.py
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from passlib.context import CryptContext
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from app.core.config import settings
from app.models.user import User
from app.services.user_service import get_user_by_email, authenticate_user
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Password context (same as in user_service.py)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def generate_password_hash(password: str) -> str:
    """Generate bcrypt hash for password"""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash"""
    return pwd_context.verify(plain_password, hashed_password)

def fix_admin_password():
    """Fix admin password in database"""
    try:
        # Create database connection
        engine = create_engine(settings.database_url)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        # Admin credentials from .env
        admin_email = "admin@lawvriksh.com"
        admin_password = "admin123"  # From .env file
        
        logger.info(f"🔧 Fixing admin password for: {admin_email}")
        
        # Generate new password hash
        new_hash = generate_password_hash(admin_password)
        logger.info(f"✅ Generated new password hash")
        
        # Check if admin user exists
        admin_user = get_user_by_email(db, admin_email)
        
        if admin_user:
            # Update existing admin user
            admin_user.password_hash = new_hash
            admin_user.is_admin = True
            admin_user.is_active = True
            db.commit()
            logger.info(f"✅ Updated existing admin user: {admin_email}")
        else:
            # Create new admin user
            from app.schemas.user import UserCreate
            from app.services.user_service import create_user
            
            admin_data = UserCreate(
                name="Admin User",
                email=admin_email,
                password=admin_password
            )
            
            admin_user = create_user(db, admin_data, is_admin=True)
            logger.info(f"✅ Created new admin user: {admin_email}")
        
        # Verify the password works
        auth_result = authenticate_user(db, admin_email, admin_password)
        if auth_result:
            logger.info(f"✅ Password verification successful!")
            logger.info(f"📋 Admin Login Credentials:")
            logger.info(f"   Email: {admin_email}")
            logger.info(f"   Password: {admin_password}")
            logger.info(f"   User ID: {auth_result.id}")
            logger.info(f"   Is Admin: {auth_result.is_admin}")
        else:
            logger.error(f"❌ Password verification failed!")
            return False
        
        db.close()
        return True
        
    except Exception as e:
        logger.error(f"❌ Error fixing admin password: {e}")
        if 'db' in locals():
            db.rollback()
            db.close()
        return False

def test_multiple_passwords():
    """Test common admin passwords and show their hashes"""
    passwords = ["admin123", "password123", "admin", "lawvriksh123"]
    
    logger.info("🔍 Testing common admin passwords:")
    logger.info("=" * 50)
    
    for password in passwords:
        hash_value = generate_password_hash(password)
        logger.info(f"Password: '{password}'")
        logger.info(f"Hash: {hash_value}")
        logger.info("-" * 30)

def main():
    """Main function"""
    logger.info("🔧 LawVriksh Admin Password Fix Tool")
    logger.info("=" * 50)
    
    # Test database connection first
    try:
        engine = create_engine(settings.database_url)
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("✅ Database connection successful")
    except Exception as e:
        logger.error(f"❌ Database connection failed: {e}")
        logger.error("Please check your .env file and MySQL server.")
        return False
    
    # Show current .env admin credentials
    logger.info(f"📋 Current .env admin credentials:")
    logger.info(f"   ADMIN_EMAIL: {getattr(settings, 'ADMIN_EMAIL', 'admin@lawvriksh.com')}")
    logger.info(f"   ADMIN_PASSWORD: {getattr(settings, 'ADMIN_PASSWORD', 'admin123')}")
    logger.info("")
    
    # Ask user what they want to do
    print("What would you like to do?")
    print("1. Fix admin password (recommended)")
    print("2. Test common passwords and show hashes")
    print("3. Both")
    
    choice = input("Enter choice (1-3): ").strip()
    
    if choice in ["1", "3"]:
        logger.info("\n🔧 Fixing admin password...")
        if fix_admin_password():
            logger.info("\n🎉 Admin password fixed successfully!")
            logger.info("You can now login to the admin panel.")
        else:
            logger.error("\n❌ Failed to fix admin password.")
            return False
    
    if choice in ["2", "3"]:
        logger.info("\n🔍 Testing password hashes...")
        test_multiple_passwords()
    
    return True

if __name__ == "__main__":
    success = main()
    input("\nPress Enter to exit...")
    sys.exit(0 if success else 1)
