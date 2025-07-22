#!/usr/bin/env python3
"""
Integration Test Script for Frontend-Backend Connection
This script tests the connection between frontend and backend.
"""

import sys
import os
import subprocess
import time
import requests
from pathlib import Path

def test_backend_health():
    """Test if backend is running and healthy."""
    print("🔄 Testing backend health...")
    
    try:
        response = requests.get("http://localhost:8000/health", timeout=5)
        if response.status_code == 200:
            print("✅ Backend is running and healthy!")
            return True
        else:
            print(f"❌ Backend health check failed with status: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Backend is not accessible: {e}")
        print("   Make sure the backend is running on port 8000")
        return False

def test_frontend_connection():
    """Test if frontend can reach backend."""
    print("🔄 Testing frontend connection to backend...")
    
    try:
        response = requests.get("http://localhost:3000", timeout=5)
        if response.status_code == 200:
            print("✅ Frontend is running!")
            return True
        else:
            print(f"❌ Frontend check failed with status: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Frontend is not accessible: {e}")
        print("   Make sure the frontend is running on port 3000")
        return False

def test_cors():
    """Test CORS configuration."""
    print("🔄 Testing CORS configuration...")
    
    try:
        headers = {
            'Origin': 'http://localhost:3000',
            'Access-Control-Request-Method': 'GET',
            'Access-Control-Request-Headers': 'Content-Type'
        }
        
        response = requests.options("http://localhost:8000/health", headers=headers, timeout=5)
        
        if 'Access-Control-Allow-Origin' in response.headers:
            print("✅ CORS is properly configured!")
            return True
        else:
            print("❌ CORS headers not found in response")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ CORS test failed: {e}")
        return False

def test_database_connection():
    """Test database connection."""
    print("🔄 Testing database connection...")
    
    try:
        import pymysql
        connection = pymysql.connect(
            host='localhost',
            port=3306,
            user='root',
            password='pabbo@123',
            database='lawvriksh_referral'
        )
        
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            if result[0] == 1:
                print("✅ Database connection successful!")
                connection.close()
                return True
        
        connection.close()
        return False
        
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        print("   Please check MySQL is running and credentials are correct")
        return False

def test_api_endpoints():
    """Test key API endpoints."""
    print("🔄 Testing API endpoints...")

    try:
        # Test signup endpoint
        signup_data = {
            "name": "Test User",
            "email": f"test_{int(time.time())}@example.com",
            "password": "testpassword123"
        }

        response = requests.post("http://localhost:8000/auth/signup", json=signup_data, timeout=5)
        if response.status_code in [200, 201]:
            print("✅ Signup endpoint working!")

            # Test leaderboard endpoint
            leaderboard_response = requests.get("http://localhost:8000/leaderboard?page=1&limit=10", timeout=5)
            if leaderboard_response.status_code == 200:
                print("✅ Leaderboard endpoint working!")
                return True
            else:
                print(f"❌ Leaderboard endpoint failed: {leaderboard_response.status_code}")
                return False
        else:
            print(f"❌ Signup endpoint failed: {response.status_code}")
            return False

    except requests.exceptions.RequestException as e:
        print(f"❌ API endpoints test failed: {e}")
        return False

def main():
    """Run all integration tests."""
    print("🚀 Starting Frontend-Backend Integration Tests")
    print("=" * 50)

    tests = [
        ("Database Connection", test_database_connection),
        ("Backend Health", test_backend_health),
        ("Frontend Connection", test_frontend_connection),
        ("CORS Configuration", test_cors),
        ("API Endpoints", test_api_endpoints),
    ]

    results = []

    for test_name, test_func in tests:
        print(f"\n📋 Running: {test_name}")
        result = test_func()
        results.append((test_name, result))

        if not result:
            print(f"⚠️  {test_name} failed!")

        time.sleep(1)  # Small delay between tests

    print("\n" + "=" * 50)
    print("📊 Integration Test Results:")
    print("=" * 50)

    all_passed = True
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name:<25} {status}")
        if not result:
            all_passed = False

    print("=" * 50)

    if all_passed:
        print("🎉 All integration tests passed! Frontend and backend are properly connected.")
        print("\n🔧 Integration Summary:")
        print("   ✅ Database: MySQL connected (lawvriksh_referral)")
        print("   ✅ Backend: FastAPI running on port 8000")
        print("   ✅ Frontend: React/Vite running on port 3000")
        print("   ✅ API: Real endpoints working (no mock data)")
        print("   ✅ CORS: Cross-origin requests enabled")
        print("\n🚀 Ready for testing! Try these features:")
        print("   • Join waitlist (signup)")
        print("   • View leaderboard")
        print("   • Share on social media")
        print("   • Admin dashboard")
    else:
        print("⚠️  Some tests failed. Please check the issues above.")
        print("\n💡 Common solutions:")
        print("   1. Make sure MySQL is running with correct credentials")
        print("   2. Start the backend: cd BetajoiningBackend && py -m uvicorn app.main:app --reload --port 8000")
        print("   3. Start the frontend: npm run dev")
        print("   4. Check .env files are properly configured")
        print("   5. Verify VITE_MOCK_MODE=false in .env")

    return all_passed

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
