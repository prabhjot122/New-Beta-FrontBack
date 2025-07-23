#!/usr/bin/env python3
"""
MySQL Database initialization script for Lawvriksh backend.
This script creates all database tables and optionally creates an admin user.
Requires MySQL server to be running and configured.
"""

import sys
import os
from pathlib import Path

# Add the backend directory to Python path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

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

def init_database():
    """Initialize the database with all tables."""
    print("🔄 Initializing database...")
    
    try:
        from app.core.dependencies import engine
        from app.core.database import Base
        
        # Create all tables
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created successfully")
        
        # Import all models to ensure they're registered
        from app.models import user, share  # This ensures all models are loaded
        
        print("✅ All models loaded successfully")
        
    except Exception as e:
        print(f"❌ Error initializing database: {e}")
        return False
    
    return True

def create_admin_user():
    """Create an admin user if it doesn't exist."""
    print("🔄 Creating admin user...")

    try:
        # Load environment variables from .env file
        env_vars = load_env_file()
        for key, value in env_vars.items():
            os.environ[key] = value

        from app.core.dependencies import get_db
        from app.models.user import User
        from passlib.context import CryptContext

        # Get database session
        db = next(get_db())

        # Get admin credentials from environment variables
        admin_email = os.getenv("ADMIN_EMAIL", "sahilsaurav2507@gmail.com")
        admin_password = os.getenv("ADMIN_PASSWORD", "Sahil@123")

        print(f"📧 Using admin email from .env: {admin_email}")
        print(f"🔑 Using admin password from .env: {admin_password}")

        # Check if admin user already exists
        existing_admin = db.query(User).filter(User.email == admin_email).first()

        if existing_admin:
            print(f"ℹ️  Admin user already exists: {admin_email}")
            # Update password if it's different
            pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
            if not pwd_context.verify(admin_password, existing_admin.password_hash):
                existing_admin.password_hash = pwd_context.hash(admin_password)
                db.commit()
                print(f"🔄 Admin password updated from environment variables")
            return True

        # Create password context
        pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

        # Create admin user
        admin_user = User(
            name="Sahil Saurav",
            email=admin_email,
            password_hash=pwd_context.hash(admin_password),
            is_admin=True,
            is_active=True
        )

        db.add(admin_user)
        db.commit()
        db.refresh(admin_user)

        print(f"✅ Admin user created successfully!")
        print(f"   Email: {admin_email}")
        print(f"   Password: {admin_password}")
        print(f"   📝 Credentials loaded from .env file")

        db.close()

    except Exception as e:
        print(f"❌ Error creating admin user: {e}")
        return False

    return True

def main():
    """Main function."""
    print("🚀 Lawvriksh Database Initialization")
    print("=" * 40)
    
    # Initialize database
    if not init_database():
        print("\n❌ Database initialization failed!")
        sys.exit(1)
    
    # Ask if user wants to create admin user
    create_admin = input("\n❓ Do you want to create an admin user? (y/N): ").lower().strip()
    
    if create_admin in ['y', 'yes']:
        if not create_admin_user():
            print("\n⚠️  Admin user creation failed, but database is initialized.")
    
    print("\n🎉 Database initialization complete!")
    print("\nYou can now start the application with:")
    print("  uvicorn app.main:app --reload --host 0.0.0.0 --port 8000")

if __name__ == "__main__":
    main()
