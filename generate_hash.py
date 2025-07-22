#!/usr/bin/env python3
"""
Generate bcrypt hash for admin123 password
"""

from passlib.context import CryptContext

# Password context (same as in user_service.py)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Generate hash for admin123
password = "admin123"
hash_value = pwd_context.hash(password)

print("=" * 60)
print("BCRYPT HASH GENERATOR")
print("=" * 60)
print(f"Password: {password}")
print(f"Hash: {hash_value}")
print("=" * 60)
print("Copy this hash to your SQL file:")
print(f"'{hash_value}'")
print("=" * 60)

# Verify the hash works
is_valid = pwd_context.verify(password, hash_value)
print(f"Verification test: {'✅ PASSED' if is_valid else '❌ FAILED'}")
