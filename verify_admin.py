#!/usr/bin/env python3
"""
Admin Verification Script for LawVriksh Platform
===============================================
This script verifies that the admin credentials in the database
match the ones specified in the .env file.

Usage:
    python verify_admin.py
"""

import os
import sys
from pathlib import Path

def load_env_file(env_path=".env"):
    """Load environment variables from .env file."""
    env_vars = {}
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip()
    return env_vars

def verify_admin_credentials():
    """Verify admin credentials against database."""
    print("🔍 Verifying admin credentials...")
    
    try:
        # Load environment variables
        env_vars = load_env_file()
        for key, value in env_vars.items():
            os.environ[key] = value
        
        from app.core.dependencies import get_db
        from app.models.user import User
        from passlib.context import CryptContext
        
        # Get credentials from environment
        admin_email = os.getenv("ADMIN_EMAIL", "sahilsaurav2507@gmail.com")
        admin_password = os.getenv("ADMIN_PASSWORD", "Sahil@123")
        
        print(f"📧 Expected Email: {admin_email}")
        print(f"🔑 Expected Password: {admin_password}")
        
        # Get database session
        db = next(get_db())
        
        # Find admin user in database
        admin_user = db.query(User).filter(User.email == admin_email).first()
        
        if not admin_user:
            print(f"❌ Admin user not found in database!")
            print(f"   Expected email: {admin_email}")
            db.close()
            return False
        
        print(f"✅ Admin user found in database:")
        print(f"   ID: {admin_user.id}")
        print(f"   Name: {admin_user.name}")
        print(f"   Email: {admin_user.email}")
        print(f"   Is Admin: {admin_user.is_admin}")
        print(f"   Is Active: {admin_user.is_active}")
        print(f"   Created: {admin_user.created_at}")
        
        # Verify password
        pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        password_matches = pwd_context.verify(admin_password, admin_user.password_hash)
        
        if password_matches:
            print(f"✅ Password verification successful!")
        else:
            print(f"❌ Password verification failed!")
            print(f"   The password in .env doesn't match the hash in database")
            db.close()
            return False
        
        # Test authentication service
        print(f"\n🔄 Testing authentication service...")
        from app.services.user_service import authenticate_user
        
        authenticated_user = authenticate_user(db, admin_email, admin_password)
        
        if authenticated_user and authenticated_user.is_admin:
            print(f"✅ Authentication service test successful!")
        else:
            print(f"❌ Authentication service test failed!")
            db.close()
            return False
        
        db.close()
        return True
        
    except Exception as e:
        print(f"❌ Error during verification: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Main verification function."""
    print("=" * 60)
    print("🔍 LawVriksh Admin Verification Script")
    print("=" * 60)
    
    # Check if .env file exists
    if not os.path.exists(".env"):
        print("❌ .env file not found!")
        return False
    
    # Verify credentials
    if verify_admin_credentials():
        print("\n" + "=" * 60)
        print("🎉 Admin verification completed successfully!")
        print("✅ All checks passed - admin login should work!")
        print("=" * 60)
        return True
    else:
        print("\n" + "=" * 60)
        print("❌ Admin verification failed!")
        print("🔧 Run 'python setup_admin.py' to fix the issue")
        print("=" * 60)
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
