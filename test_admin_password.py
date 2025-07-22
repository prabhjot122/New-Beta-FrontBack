#!/usr/bin/env python3
"""
Test Admin Password Script
=========================
This script will directly test password verification
and show exactly what's happening with the admin login.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from passlib.context import CryptContext
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from app.core.config import settings
from app.services.user_service import get_user_by_email, authenticate_user
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Password context (same as in user_service.py)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def test_database_connection():
    """Test database connection"""
    try:
        engine = create_engine(settings.database_url)
        with engine.connect() as conn:
            result = conn.execute(text("SELECT DATABASE() as db_name"))
            db_name = result.fetchone()[0]
            logger.info(f"✅ Connected to database: {db_name}")
            return True
    except Exception as e:
        logger.error(f"❌ Database connection failed: {e}")
        return False

def check_admin_user():
    """Check admin user in database"""
    try:
        engine = create_engine(settings.database_url)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        # Check if admin user exists
        admin_user = get_user_by_email(db, "admin@lawvriksh.com")
        
        if admin_user:
            logger.info(f"✅ Admin user found:")
            logger.info(f"   ID: {admin_user.id}")
            logger.info(f"   Name: {admin_user.name}")
            logger.info(f"   Email: {admin_user.email}")
            logger.info(f"   Is Admin: {admin_user.is_admin}")
            logger.info(f"   Is Active: {admin_user.is_active}")
            logger.info(f"   Password Hash: {admin_user.password_hash[:50]}...")
            
            # Test password verification
            test_passwords = ["admin123", "password123", "admin", "lawvriksh123"]
            
            logger.info(f"\n🔍 Testing passwords:")
            for password in test_passwords:
                is_valid = pwd_context.verify(password, admin_user.password_hash)
                status = "✅ CORRECT" if is_valid else "❌ WRONG"
                logger.info(f"   '{password}': {status}")
            
            db.close()
            return admin_user
        else:
            logger.error(f"❌ Admin user not found in database")
            db.close()
            return None
            
    except Exception as e:
        logger.error(f"❌ Error checking admin user: {e}")
        return None

def test_authentication():
    """Test authentication service"""
    try:
        engine = create_engine(settings.database_url)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        test_credentials = [
            ("admin@lawvriksh.com", "admin123"),
            ("admin@lawvriksh.com", "password123"),
            ("admin@lawvriksh.com", "admin"),
        ]
        
        logger.info(f"\n🔐 Testing authentication service:")
        for email, password in test_credentials:
            try:
                user = authenticate_user(db, email, password)
                if user:
                    logger.info(f"   ✅ SUCCESS: {email} / {password}")
                    logger.info(f"      User ID: {user.id}, Admin: {user.is_admin}")
                else:
                    logger.info(f"   ❌ FAILED: {email} / {password}")
            except Exception as e:
                logger.info(f"   ❌ ERROR: {email} / {password} - {e}")
        
        db.close()
        
    except Exception as e:
        logger.error(f"❌ Error testing authentication: {e}")

def fix_admin_password():
    """Fix admin password if needed"""
    try:
        engine = create_engine(settings.database_url)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        # Generate correct hash for 'admin123'
        correct_hash = pwd_context.hash("admin123")
        logger.info(f"🔧 Generated new hash for 'admin123': {correct_hash[:50]}...")
        
        # Update or create admin user
        admin_user = get_user_by_email(db, "admin@lawvriksh.com")
        
        if admin_user:
            # Update existing user
            admin_user.password_hash = correct_hash
            admin_user.is_admin = True
            admin_user.is_active = True
            db.commit()
            logger.info(f"✅ Updated existing admin user")
        else:
            # Create new admin user
            from app.models.user import User
            admin_user = User(
                name="Admin User",
                email="admin@lawvriksh.com",
                password_hash=correct_hash,
                is_admin=True,
                is_active=True,
                total_points=0,
                shares_count=0
            )
            db.add(admin_user)
            db.commit()
            logger.info(f"✅ Created new admin user")
        
        db.close()
        return True
        
    except Exception as e:
        logger.error(f"❌ Error fixing admin password: {e}")
        return False

def main():
    """Main function"""
    logger.info("🔧 LawVriksh Admin Login Debug Tool")
    logger.info("=" * 50)
    
    # Test 1: Database connection
    if not test_database_connection():
        return False
    
    # Test 2: Check admin user
    logger.info(f"\n📋 Checking admin user in database:")
    admin_user = check_admin_user()
    
    # Test 3: Test authentication
    test_authentication()
    
    # Test 4: Offer to fix
    if not admin_user or input(f"\n🔧 Fix admin password? (y/N): ").lower() in ['y', 'yes']:
        logger.info(f"\n🔧 Fixing admin password...")
        if fix_admin_password():
            logger.info(f"✅ Admin password fixed!")
            logger.info(f"\n🎯 Try logging in with:")
            logger.info(f"   Email: admin@lawvriksh.com")
            logger.info(f"   Password: admin123")
            
            # Test again
            logger.info(f"\n🔄 Testing fixed authentication:")
            test_authentication()
        else:
            logger.error(f"❌ Failed to fix admin password")
    
    return True

if __name__ == "__main__":
    success = main()
    input(f"\nPress Enter to exit...")
    sys.exit(0 if success else 1)
