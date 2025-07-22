#!/usr/bin/env python3
"""
Development Startup Script for LawVriksh
This script helps start both frontend and backend for development.
"""

import sys
import os
import subprocess
import time
import signal
from pathlib import Path
import threading

class DevelopmentServer:
    def __init__(self):
        self.backend_process = None
        self.frontend_process = None
        self.running = True
        
    def start_backend(self):
        """Start the FastAPI backend server."""
        print("🚀 Starting Backend Server...")
        
        backend_dir = Path("BetajoiningBackend")
        if not backend_dir.exists():
            print("❌ Backend directory not found!")
            return False
        
        try:
            # Change to backend directory and start uvicorn
            self.backend_process = subprocess.Popen(
                [sys.executable, "-m", "uvicorn", "app.main:app", "--reload", "--port", "8000", "--host", "0.0.0.0"],
                cwd=backend_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            print("✅ Backend server starting on http://localhost:8000")
            return True
            
        except Exception as e:
            print(f"❌ Failed to start backend: {e}")
            return False
    
    def start_frontend(self):
        """Start the React frontend server."""
        print("🚀 Starting Frontend Server...")
        
        try:
            # Start npm dev server
            self.frontend_process = subprocess.Popen(
                ["npm", "run", "dev"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            print("✅ Frontend server starting on http://localhost:3000")
            return True
            
        except Exception as e:
            print(f"❌ Failed to start frontend: {e}")
            return False
    
    def monitor_processes(self):
        """Monitor both processes and restart if needed."""
        while self.running:
            time.sleep(5)
            
            # Check backend
            if self.backend_process and self.backend_process.poll() is not None:
                print("⚠️  Backend process stopped unexpectedly")
                
            # Check frontend
            if self.frontend_process and self.frontend_process.poll() is not None:
                print("⚠️  Frontend process stopped unexpectedly")
    
    def stop_servers(self):
        """Stop both servers gracefully."""
        print("\n🛑 Stopping development servers...")
        self.running = False
        
        if self.backend_process:
            try:
                self.backend_process.terminate()
                self.backend_process.wait(timeout=5)
                print("✅ Backend server stopped")
            except subprocess.TimeoutExpired:
                self.backend_process.kill()
                print("⚠️  Backend server force killed")
        
        if self.frontend_process:
            try:
                self.frontend_process.terminate()
                self.frontend_process.wait(timeout=5)
                print("✅ Frontend server stopped")
            except subprocess.TimeoutExpired:
                self.frontend_process.kill()
                print("⚠️  Frontend server force killed")
    
    def signal_handler(self, signum, frame):
        """Handle Ctrl+C gracefully."""
        print("\n🔄 Received interrupt signal...")
        self.stop_servers()
        sys.exit(0)

def check_prerequisites():
    """Check if all prerequisites are met."""
    print("🔍 Checking prerequisites...")
    
    # Check if Node.js is installed
    try:
        result = subprocess.run(["node", "--version"], capture_output=True, text=True)
        print(f"✅ Node.js: {result.stdout.strip()}")
    except FileNotFoundError:
        print("❌ Node.js not found. Please install Node.js")
        return False
    
    # Check if npm is installed
    try:
        result = subprocess.run(["npm", "--version"], capture_output=True, text=True)
        print(f"✅ npm: {result.stdout.strip()}")
    except FileNotFoundError:
        print("❌ npm not found. Please install npm")
        return False
    
    # Check if Python dependencies are installed
    try:
        import uvicorn
        import fastapi
        print("✅ Python dependencies available")
    except ImportError as e:
        print(f"❌ Missing Python dependencies: {e}")
        print("   Run: cd BetajoiningBackend && pip install -r requirements.txt")
        return False
    
    # Check if node_modules exists
    if not Path("node_modules").exists():
        print("❌ Frontend dependencies not installed")
        print("   Run: npm install")
        return False
    else:
        print("✅ Frontend dependencies installed")
    
    # Check if .env files exist
    if not Path(".env").exists():
        print("⚠️  Frontend .env file not found (but created automatically)")
    else:
        print("✅ Frontend .env file exists")
    
    if not Path("BetajoiningBackend/.env").exists():
        print("⚠️  Backend .env file not found (but created automatically)")
    else:
        print("✅ Backend .env file exists")
    
    return True

def main():
    """Main function to start development environment."""
    print("🎯 LawVriksh Development Environment Startup")
    print("=" * 50)
    
    # Check prerequisites
    if not check_prerequisites():
        print("\n❌ Prerequisites not met. Please fix the issues above.")
        return False
    
    print("\n🚀 Starting development servers...")
    
    # Create server instance
    server = DevelopmentServer()
    
    # Set up signal handler for graceful shutdown
    signal.signal(signal.SIGINT, server.signal_handler)
    signal.signal(signal.SIGTERM, server.signal_handler)
    
    # Start backend
    if not server.start_backend():
        return False
    
    # Wait a bit for backend to start
    time.sleep(3)
    
    # Start frontend
    if not server.start_frontend():
        server.stop_servers()
        return False
    
    print("\n" + "=" * 50)
    print("🎉 Development environment is starting!")
    print("📱 Frontend: http://localhost:3000")
    print("🔧 Backend:  http://localhost:8000")
    print("📚 API Docs: http://localhost:8000/docs")
    print("=" * 50)
    print("💡 Press Ctrl+C to stop all servers")
    print("=" * 50)
    
    # Start monitoring in a separate thread
    monitor_thread = threading.Thread(target=server.monitor_processes)
    monitor_thread.daemon = True
    monitor_thread.start()
    
    try:
        # Keep the main thread alive
        while server.running:
            time.sleep(1)
    except KeyboardInterrupt:
        server.signal_handler(signal.SIGINT, None)
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
