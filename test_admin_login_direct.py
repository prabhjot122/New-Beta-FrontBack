#!/usr/bin/env python3
"""
Test admin login directly with the exact same request format as frontend
"""

import requests
import json

def test_admin_login():
    """Test admin login with exact frontend format"""
    
    BASE_URL = "http://localhost:8000"
    
    # Test credentials
    credentials = {
        "email": "admin@lawvriksh.com",
        "password": "admin123"
    }
    
    print("🔧 Testing Admin Login - Direct API Call")
    print("=" * 50)
    print(f"URL: {BASE_URL}/auth/login")
    print(f"Credentials: {credentials}")
    print()
    
    try:
        # Make the exact same request as frontend
        headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        }
        
        response = requests.post(
            f"{BASE_URL}/auth/login",
            json=credentials,
            headers=headers,
            timeout=10
        )
        
        print(f"Status Code: {response.status_code}")
        print(f"Headers: {dict(response.headers)}")
        print()
        
        if response.status_code == 200:
            # Success
            data = response.json()
            print("✅ LOGIN SUCCESSFUL!")
            print(f"Access Token: {data.get('access_token', 'N/A')[:50]}...")
            print(f"Token Type: {data.get('token_type', 'N/A')}")
            print(f"Expires In: {data.get('expires_in', 'N/A')} seconds")
            
            # Test getting user info with token
            print("\n🔄 Testing /auth/me endpoint...")
            auth_headers = {
                'Authorization': f"Bearer {data.get('access_token')}",
                'Content-Type': 'application/json'
            }
            
            me_response = requests.get(f"{BASE_URL}/auth/me", headers=auth_headers)
            print(f"Status Code: {me_response.status_code}")
            
            if me_response.status_code == 200:
                user_data = me_response.json()
                print("✅ USER INFO RETRIEVED!")
                print(f"User ID: {user_data.get('user_id')}")
                print(f"Name: {user_data.get('name')}")
                print(f"Email: {user_data.get('email')}")
                print(f"Is Admin: {user_data.get('is_admin')}")
            else:
                print(f"❌ Failed to get user info: {me_response.text}")
            
        else:
            # Error
            print("❌ LOGIN FAILED!")
            print(f"Response: {response.text}")
            
            # Try to parse error details
            try:
                error_data = response.json()
                print(f"Error Details: {error_data}")
            except:
                print("Could not parse error response as JSON")
    
    except requests.exceptions.ConnectionError:
        print("❌ CONNECTION ERROR!")
        print("Backend server is not running or not accessible at http://localhost:8000")
        print("Make sure your backend server is started.")
        
    except requests.exceptions.Timeout:
        print("❌ TIMEOUT ERROR!")
        print("Request timed out after 10 seconds")
        
    except Exception as e:
        print(f"❌ UNEXPECTED ERROR: {e}")

def test_database_admin():
    """Test if admin exists in database"""
    print("\n🔍 Testing Database Admin User")
    print("=" * 50)
    
    try:
        # Test database connection endpoint
        response = requests.get("http://localhost:8000/health", timeout=5)
        if response.status_code == 200:
            print("✅ Backend server is running")
        else:
            print(f"⚠️ Backend health check returned: {response.status_code}")
    except:
        print("❌ Backend server is not accessible")
        return
    
    # You could add database query here if you have an endpoint for it

if __name__ == "__main__":
    test_database_admin()
    test_admin_login()
    
    print("\n" + "=" * 50)
    print("🎯 SUMMARY:")
    print("If login failed, the issue is likely:")
    print("1. Admin user doesn't exist in database")
    print("2. Password hash is incorrect")
    print("3. Database connection issues")
    print("4. Backend authentication logic problems")
    print()
    print("Next steps:")
    print("1. Run the updated lawdata.sql file")
    print("2. Restart backend server")
    print("3. Try this test again")
    input("\nPress Enter to exit...")
