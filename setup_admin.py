#!/usr/bin/env python3
"""
Admin Setup Script for LawVriksh Platform
==========================================
This script ensures the admin user is properly created with credentials from .env file.
It can be run independently or as part of the database initialization process.

Usage:
    python setup_admin.py

Environment Variables Required:
    ADMIN_EMAIL=sahilsaurav2507@gmail.com
    ADMIN_PASSWORD=Sahil@123
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

def setup_admin_user():
    """Setup admin user with credentials from environment variables."""
    print("🔧 Setting up admin user from .env file...")
    
    try:
        # Load environment variables
        env_vars = load_env_file()
        
        # Set environment variables for the current process
        for key, value in env_vars.items():
            os.environ[key] = value
        
        # Import after setting environment variables
        from app.core.dependencies import get_db
        from app.models.user import User
        from passlib.context import CryptContext
        
        # Get admin credentials from environment
        admin_email = os.getenv("ADMIN_EMAIL", "sahilsaurav2507@gmail.com")
        admin_password = os.getenv("ADMIN_PASSWORD", "Sahil@123")
        
        print(f"📧 Admin Email: {admin_email}")
        print(f"🔑 Admin Password: {admin_password}")
        
        # Get database session
        db = next(get_db())
        
        # Check if admin user already exists
        existing_admin = db.query(User).filter(User.email == admin_email).first()
        
        # Create password context
        pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        
        if existing_admin:
            print(f"ℹ️  Admin user already exists: {admin_email}")
            
            # Verify password is correct
            if pwd_context.verify(admin_password, existing_admin.password_hash):
                print(f"✅ Admin password is correct")
            else:
                print(f"🔄 Updating admin password...")
                existing_admin.password_hash = pwd_context.hash(admin_password)
                existing_admin.name = "Sahil Saurav"  # Ensure name is correct
                existing_admin.is_admin = True
                existing_admin.is_active = True
                db.commit()
                print(f"✅ Admin password updated successfully")
            
            db.close()
            return True
        
        # Create new admin user
        print(f"🆕 Creating new admin user...")
        admin_user = User(
            name="Sahil Saurav",
            email=admin_email,
            password_hash=pwd_context.hash(admin_password),
            is_admin=True,
            is_active=True,
            total_points=0,
            shares_count=0
        )
        
        db.add(admin_user)
        db.commit()
        db.refresh(admin_user)
        
        print(f"✅ Admin user created successfully!")
        print(f"   ID: {admin_user.id}")
        print(f"   Name: {admin_user.name}")
        print(f"   Email: {admin_user.email}")
        print(f"   Is Admin: {admin_user.is_admin}")
        print(f"   Is Active: {admin_user.is_active}")
        
        db.close()
        return True
        
    except Exception as e:
        print(f"❌ Error setting up admin user: {e}")
        import traceback
        traceback.print_exc()
        return False

def verify_admin_login():
    """Verify that admin login works with the credentials."""
    print("\n🔍 Verifying admin login...")
    
    try:
        from app.services.user_service import authenticate_user
        from app.core.dependencies import get_db
        
        admin_email = os.getenv("ADMIN_EMAIL", "sahilsaurav2507@gmail.com")
        admin_password = os.getenv("ADMIN_PASSWORD", "Sahil@123")
        
        db = next(get_db())
        user = authenticate_user(db, admin_email, admin_password)
        db.close()
        
        if user and user.is_admin:
            print(f"✅ Admin login verification successful!")
            print(f"   User ID: {user.id}")
            print(f"   Name: {user.name}")
            print(f"   Email: {user.email}")
            return True
        else:
            print(f"❌ Admin login verification failed!")
            return False
            
    except Exception as e:
        print(f"❌ Error verifying admin login: {e}")
        return False

def main():
    """Main function to setup and verify admin user."""
    print("=" * 60)
    print("🚀 LawVriksh Admin Setup Script")
    print("=" * 60)
    
    # Check if .env file exists
    if not os.path.exists(".env"):
        print("❌ .env file not found!")
        print("Please create a .env file with ADMIN_EMAIL and ADMIN_PASSWORD")
        return False
    
    # Setup admin user
    if not setup_admin_user():
        print("❌ Failed to setup admin user")
        return False
    
    # Verify admin login
    if not verify_admin_login():
        print("❌ Failed to verify admin login")
        return False
    
    print("\n" + "=" * 60)
    print("🎉 Admin setup completed successfully!")
    print("=" * 60)
    print(f"📧 Email: {os.getenv('ADMIN_EMAIL', 'sahilsaurav2507@gmail.com')}")
    print(f"🔑 Password: {os.getenv('ADMIN_PASSWORD', 'Sahil@123')}")
    print("🌐 You can now login to the admin panel!")
    print("=" * 60)
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
