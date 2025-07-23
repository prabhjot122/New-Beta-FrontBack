#!/usr/bin/env python3
"""
Corrected Admin Setup Script
============================
Creates admin user with password_hash column (matching the code)
Beta users have password_hash = NULL, admin users have hashed password
"""

import os
import bcrypt
from sqlalchemy import create_engine, text

DATABASE_URL = "mysql+pymysql://lawvriksh_user:Sahil123@mysql:3306/lawvriksh_referral"
ADMIN_EMAIL = "sahilsaurav2507@gmail.com"
ADMIN_PASSWORD = "Sahil@123"

def setup_admin():
    try:
        print("🔧 Setting up admin user (corrected schema)...")
        engine = create_engine(DATABASE_URL)
        
        # Hash password for admin
        hashed_password = bcrypt.hashpw(ADMIN_PASSWORD.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        with engine.connect() as conn:
            # Insert/update admin user (with password_hash)
            conn.execute(text("""
                INSERT INTO users (name, email, password_hash, is_admin, is_active, user_type, total_points, shares_count)
                VALUES (:name, :email, :password_hash, 1, 1, 'admin', 0, 0)
                ON DUPLICATE KEY UPDATE 
                    password_hash = :password_hash, 
                    is_admin = 1, 
                    is_active = 1,
                    user_type = 'admin',
                    updated_at = NOW()
            """), {
                "name": "Admin User",
                "email": ADMIN_EMAIL,
                "password_hash": hashed_password
            })
            conn.commit()
            print(f"✅ Admin user {ADMIN_EMAIL} created with password authentication")
            
            # Verify admin user
            result = conn.execute(text("""
                SELECT id, name, email, is_admin, is_active, user_type, 
                       CASE WHEN password_hash IS NOT NULL THEN 'Yes' ELSE 'No' END as has_password
                FROM users WHERE email = :email
            """), {"email": ADMIN_EMAIL})
            
            user = result.fetchone()
            if user:
                print(f"✅ Admin verification:")
                print(f"   ID: {user.id}")
                print(f"   Name: {user.name}")
                print(f"   Email: {user.email}")
                print(f"   Is Admin: {bool(user.is_admin)}")
                print(f"   User Type: {user.user_type}")
                print(f"   Has Password: {user.has_password}")
                print(f"   Is Active: {bool(user.is_active)}")
                return True
            else:
                print("❌ Admin user not found after creation")
                return False
                
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = setup_admin()
    if success:
        print("🎉 Admin setup completed successfully!")
        print("📝 Beta users will be created WITHOUT passwords (password_hash = NULL)")
        print("🔐 Admin users have password_hash for authentication")
    else:
        print("💥 Admin setup failed!")
