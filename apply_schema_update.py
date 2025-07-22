#!/usr/bin/env python3
"""
Database Schema Update Script
============================

This script applies the updated lawdata.sql schema to your MySQL database.
Run this after making changes to lawdata.sql to sync your database.

Usage:
    python apply_schema_update.py

Requirements:
    - MySQL server running
    - Database credentials in .env file
    - lawdata.sql file in the same directory
"""

import os
import sys
import subprocess
from pathlib import Path

def load_env():
    """Load environment variables from .env file"""
    env_file = Path(__file__).parent / '.env'
    if not env_file.exists():
        print("❌ Error: .env file not found!")
        print("Please create a .env file with your database credentials.")
        sys.exit(1)
    
    env_vars = {}
    with open(env_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                env_vars[key] = value
    
    return env_vars

def apply_sql_schema():
    """Apply the lawdata.sql schema to the database"""
    print("🔄 Applying database schema updates...")
    
    # Load environment variables
    env_vars = load_env()
    
    # Get database credentials
    db_user = env_vars.get('DB_USER', 'root')
    db_password = env_vars.get('DB_PASSWORD', '')
    db_host = env_vars.get('DB_HOST', 'localhost')
    db_port = env_vars.get('DB_PORT', '3306')
    
    # Check if lawdata.sql exists
    sql_file = Path(__file__).parent / 'lawdata.sql'
    if not sql_file.exists():
        print("❌ Error: lawdata.sql file not found!")
        sys.exit(1)
    
    print(f"📁 Found SQL file: {sql_file}")
    print(f"🔗 Connecting to MySQL at {db_host}:{db_port} as {db_user}")
    
    try:
        # Build MySQL command
        mysql_cmd = [
            'mysql',
            f'-h{db_host}',
            f'-P{db_port}',
            f'-u{db_user}',
            f'-p{db_password}',
            '--default-character-set=utf8mb4'
        ]
        
        # Execute the SQL file
        with open(sql_file, 'r', encoding='utf-8') as f:
            result = subprocess.run(
                mysql_cmd,
                input=f.read(),
                text=True,
                capture_output=True
            )
        
        if result.returncode == 0:
            print("✅ Database schema updated successfully!")
            print("📊 Summary:")
            print("   - Tables recreated with latest schema")
            print("   - Indexes and constraints applied")
            print("   - Sample data inserted (if any)")
            print("\n🚀 You can now restart your backend server.")
            
        else:
            print("❌ Error applying schema:")
            print(result.stderr)
            print("\n💡 Troubleshooting tips:")
            print("   1. Check if MySQL server is running")
            print("   2. Verify database credentials in .env file")
            print("   3. Ensure you have proper database permissions")
            
    except FileNotFoundError:
        print("❌ Error: MySQL client not found!")
        print("Please install MySQL client or ensure it's in your PATH.")
        print("\nOn Windows:")
        print("   - Install MySQL Workbench or MySQL Command Line Client")
        print("   - Add MySQL bin directory to your PATH")
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

def main():
    """Main function"""
    print("🔧 LawVriksh Database Schema Update Tool")
    print("=" * 50)
    
    # Confirm with user
    response = input("This will update your database schema. Continue? (y/N): ")
    if response.lower() not in ['y', 'yes']:
        print("❌ Operation cancelled.")
        sys.exit(0)
    
    apply_sql_schema()

if __name__ == "__main__":
    main()
