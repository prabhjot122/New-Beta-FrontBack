#!/usr/bin/env python3
"""
Generate bcrypt hash for admin password from environment variables.
This script reads the ADMIN_PASSWORD from .env file and generates the bcrypt hash
that can be used in SQL files.
"""

import os
import sys
from pathlib import Path
from passlib.context import CryptContext

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

def generate_admin_hash():
    """Generate bcrypt hash for admin password."""
    # Load environment variables
    env_vars = load_env_file()
    
    # Get admin credentials
    admin_email = env_vars.get('ADMIN_EMAIL', 'sahilsaurav2507@gmail.com')
    admin_password = env_vars.get('ADMIN_PASSWORD', 'Sahil@123')
    
    print(f"📧 Admin Email: {admin_email}")
    print(f"🔑 Admin Password: {admin_password}")
    
    # Create password context
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    
    # Generate hash
    password_hash = pwd_context.hash(admin_password)
    
    print(f"\n🔐 Generated bcrypt hash:")
    print(f"{password_hash}")
    
    # Generate SQL INSERT statement
    sql_insert = f"""
-- Admin user with credentials from .env file
DELETE FROM users WHERE is_admin = TRUE;
INSERT INTO users (name, email, password_hash, is_admin, is_active, total_points, shares_count, default_rank, current_rank)
VALUES ('Sahil Saurav', '{admin_email}', '{password_hash}', TRUE, TRUE, 0, 0, NULL, NULL);
"""
    
    print(f"\n📝 SQL INSERT statement:")
    print(sql_insert)
    
    # Save to file
    with open('admin_insert.sql', 'w') as f:
        f.write(sql_insert)
    
    print(f"\n✅ SQL statement saved to 'admin_insert.sql'")
    print(f"🔄 You can now update lawdata.sql with this hash")
    
    return password_hash, admin_email

if __name__ == "__main__":
    try:
        generate_admin_hash()
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
