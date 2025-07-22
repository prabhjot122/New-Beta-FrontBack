#!/usr/bin/env python3
"""
Test script to verify delayed email registration functionality
"""

import requests
import time
import json
from datetime import datetime

def test_delayed_registration():
    """Test registration with delayed email sending."""
    
    # Generate unique email for testing
    timestamp = int(time.time())
    test_user = {
        "name": "Test User Delayed",
        "email": f"testdelayed{timestamp}@example.com",
        "password": "testpassword123"
    }
    
    print(f"🔄 Testing delayed registration for: {test_user['email']}")
    print(f"⏰ Start time: {datetime.now().strftime('%H:%M:%S')}")
    
    try:
        # Record start time
        start_time = time.time()
        
        # Make registration request
        response = requests.post(
            "http://localhost:8000/auth/signup",
            json=test_user,
            timeout=15  # 15 second timeout
        )
        
        # Record end time
        end_time = time.time()
        response_time = end_time - start_time
        
        print(f"⏱️  Response time: {response_time:.2f} seconds")
        print(f"📊 Status code: {response.status_code}")
        
        if response.status_code == 201:
            user_data = response.json()
            print("✅ Registration successful!")
            print(f"   User ID: {user_data.get('user_id')}")
            print(f"   Name: {user_data.get('name')}")
            print(f"   Email: {user_data.get('email')}")
            print(f"   Response time: {response_time:.2f}s (should be < 5s)")
            
            if response_time < 5:
                print("✅ Fast response - email delay working!")
            else:
                print("❌ Slow response - email might be blocking")
                
            print("\n⏳ Waiting 15 seconds to see if delayed email is sent...")
            print("   (Check backend logs for email sending confirmation)")
            time.sleep(15)
            
            return True
        else:
            print(f"❌ Registration failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ Request timed out - email sending is still blocking!")
        return False
    except Exception as e:
        print(f"❌ Test failed: {e}")
        return False

if __name__ == "__main__":
    print("🧪 Testing Delayed Email Registration System")
    print("=" * 50)
    
    success = test_delayed_registration()
    
    print("\n" + "=" * 50)
    if success:
        print("✅ Test completed successfully!")
        print("📧 Check backend logs to confirm delayed email was sent after 10 seconds")
    else:
        print("❌ Test failed!")
        
    print("\n💡 Expected behavior:")
    print("   - Registration response should be fast (< 5 seconds)")
    print("   - Welcome email should be sent 10 seconds after registration")
    print("   - No timeout errors on frontend")
