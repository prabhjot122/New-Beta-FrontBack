# Frontend-Backend Integration Guide

This guide explains how to integrate the React frontend with the FastAPI backend for the LawVriksh project.

## 🔧 Configuration Summary

### Database Configuration
- **Host**: localhost
- **Port**: 3306
- **User**: root
- **Password**: pabbo@123
- **Database**: lawvriksh_referral *(Updated to match SQL file)*

### Server Ports
- **Frontend**: http://localhost:3000
- **Backend**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

### Integration Status
- ✅ **Mock Mode**: DISABLED (`VITE_MOCK_MODE=false`)
- ✅ **Real API**: All services use backend endpoints
- ✅ **Social Sharing**: Integrated with share tracking
- ✅ **Error Handling**: Enhanced with loading states
- ✅ **CORS**: Configured for frontend-backend communication

## 📁 Files Created/Modified

### Backend Configuration
1. **`BetajoiningBackend/.env`** - Database and environment configuration
2. **`BetajoiningBackend/app/core/config.py`** - Added frontend URL configuration
3. **`BetajoiningBackend/app/main.py`** - Updated CORS settings

### Frontend Configuration
1. **`.env`** - API URL and feature flags configuration

### Integration Tools
1. **`test_integration.py`** - Integration testing script
2. **`start_development.py`** - Development environment startup script

## 🚀 Quick Start

### Option 1: Automated Startup (Recommended)
```bash
# Install Python dependencies (if not already done)
cd BetajoiningBackend
pip install -r requirements.txt
cd ..

# Install Node.js dependencies (if not already done)
npm install

# Start both servers automatically
python start_development.py
```

### Option 2: Manual Startup
```bash
# Terminal 1: Start Backend
cd BetajoiningBackend
uvicorn app.main:app --reload --port 8000

# Terminal 2: Start Frontend
npm run dev
```

## 🧪 Testing the Integration

Run the integration test to verify everything is working:

```bash
python test_integration.py
```

This will test:
- ✅ Database connection
- ✅ Backend health
- ✅ Frontend accessibility
- ✅ CORS configuration

## 🔍 Troubleshooting

### Common Issues

#### 1. Database Connection Failed
**Error**: `Database connection failed: (2003, "Can't connect to MySQL server")`

**Solutions**:
- Ensure MySQL is running
- Verify credentials in `BetajoiningBackend/.env`
- Check if database `lawvriksh` exists

#### 2. Backend Not Starting
**Error**: `ModuleNotFoundError` or import errors

**Solutions**:
```bash
cd BetajoiningBackend
pip install -r requirements.txt
```

#### 3. Frontend Can't Reach Backend
**Error**: Network errors in browser console

**Solutions**:
- Check backend is running on port 8000
- Verify CORS configuration
- Check `.env` file has correct `VITE_API_URL`

#### 4. CORS Errors
**Error**: `Access to fetch at 'http://localhost:8000' from origin 'http://localhost:3000' has been blocked by CORS policy`

**Solutions**:
- Backend CORS is already configured for localhost:3000
- Restart backend server
- Check browser developer tools for specific error

### Database Setup

If you need to set up the database:

```bash
cd BetajoiningBackend
python setup_mysql_db.py
```

## 📊 Environment Variables

### Frontend (.env)
```env
VITE_API_URL=http://localhost:8000
VITE_API_TIMEOUT=10000
VITE_API_RETRY_ATTEMPTS=3
VITE_MOCK_MODE=false
```

### Backend (BetajoiningBackend/.env)
```env
DB_USER=root
DB_PASSWORD=pabbo@123
DB_NAME=lawvriksh
DB_HOST=localhost
DB_PORT=3306
DATABASE_URL=mysql+pymysql://root:pabbo%40123@localhost:3306/lawvriksh
FRONTEND_URL=http://localhost:3000
```

## 🔗 API Endpoints

The frontend is configured to use these main endpoints:

- **Authentication**: `/auth/login`, `/auth/signup`
- **Users**: `/users/profile`, `/users/view`
- **Shares**: `/shares/{platform}`, `/shares/analytics`
- **Leaderboard**: `/leaderboard`, `/leaderboard/around-me`
- **Admin**: `/admin/login`, `/admin/dashboard`

## 🛠 Development Workflow

1. **Start Development Environment**:
   ```bash
   python start_development.py
   ```

2. **Make Changes**:
   - Frontend changes auto-reload (Vite HMR)
   - Backend changes auto-reload (uvicorn --reload)

3. **Test Integration**:
   ```bash
   python test_integration.py
   ```

4. **Stop Servers**:
   - Press `Ctrl+C` in the terminal running `start_development.py`

## 📝 Next Steps

After successful integration:

1. **Test Core Features**:
   - User registration/login
   - Social sharing functionality
   - Leaderboard display
   - Admin dashboard

2. **Configure Email** (if needed):
   - Update SMTP settings in `BetajoiningBackend/.env`
   - Test email functionality

3. **Production Deployment**:
   - Update environment variables for production
   - Configure proper CORS origins
   - Set up SSL certificates

## 🆘 Getting Help

If you encounter issues:

1. Check the console output for error messages
2. Run `python test_integration.py` to identify specific problems
3. Verify all prerequisites are installed
4. Check that MySQL is running and accessible

The integration should now be complete! Both frontend and backend are configured to work together seamlessly.
