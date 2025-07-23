# Admin Credentials Setup Guide

This guide explains how admin credentials are managed in the LawVriksh platform and ensures they are properly loaded from the `.env` file.

## 📋 Overview

The admin credentials are centrally managed through environment variables in the `.env` file:

```bash
ADMIN_EMAIL=sahilsaurav2507@gmail.com
ADMIN_PASSWORD=Sahil@123
```

## 🔧 Files Updated

### 1. Environment Configuration
- **`.env`** - Contains the admin credentials
- **`Frontend/.env`** - Frontend environment variables for API communication

### 2. Database Files
- **`lawdata.sql`** - Updated with correct bcrypt hash for the admin password
- **`init_db.py`** - Loads admin credentials from `.env` file

### 3. Setup Scripts
- **`setup_admin.py`** - Creates/updates admin user from `.env` credentials
- **`verify_admin.py`** - Verifies admin credentials match database
- **`generate_admin_hash.py`** - Generates bcrypt hash for passwords

## 🚀 Quick Setup

### Method 1: Using SQL File (Recommended)
```bash
# Run the complete SQL setup
mysql -u root -p < lawdata.sql
```

### Method 2: Using Python Scripts
```bash
# Initialize database and create admin user
python init_db.py

# Or setup admin user separately
python setup_admin.py

# Verify admin credentials
python verify_admin.py
```

## 🔍 Verification Steps

1. **Check .env file exists and contains:**
   ```bash
   ADMIN_EMAIL=sahilsaurav2507@gmail.com
   ADMIN_PASSWORD=Sahil@123
   ```

2. **Run verification script:**
   ```bash
   python verify_admin.py
   ```

3. **Test admin login:**
   - Email: `sahilsaurav2507@gmail.com`
   - Password: `Sahil@123`

## 🔐 Password Hash Details

The current bcrypt hash for password "Sahil@123":
```
$2b$12$nRFTpXbD6zQhvbBCDFyiCu4S6nDTE9pwGTmecujnrGWy0B47.PMuu
```

This hash is automatically generated and updated in:
- `lawdata.sql` (line 465)
- Database when running `setup_admin.py`

## 🛠️ Troubleshooting

### Admin Login Not Working?

1. **Run the verification script:**
   ```bash
   python verify_admin.py
   ```

2. **Reset admin credentials:**
   ```bash
   python setup_admin.py
   ```

3. **Check database directly:**
   ```sql
   SELECT id, name, email, is_admin, is_active 
   FROM users 
   WHERE email = 'sahilsaurav2507@gmail.com';
   ```

### Password Hash Mismatch?

1. **Generate new hash:**
   ```bash
   python generate_admin_hash.py
   ```

2. **Update SQL file with new hash**

3. **Re-run database setup**

## 📁 File Structure

```
├── .env                     # Main environment variables
├── lawdata.sql             # Database schema with admin user
├── init_db.py              # Database initialization
├── setup_admin.py          # Admin user setup script
├── verify_admin.py         # Admin verification script
├── generate_admin_hash.py  # Password hash generator
└── Frontend/
    ├── .env                # Frontend environment variables
    ├── .env.local          # Local development overrides
    └── .env.example        # Environment template
```

## 🔄 Environment Variable Priority

1. **Backend (.env):**
   - `ADMIN_EMAIL=sahilsaurav2507@gmail.com`
   - `ADMIN_PASSWORD=Sahil@123`
   - `FRONTEND_URL=https://lawvriksh.com`

2. **Frontend (Frontend/.env):**
   - `VITE_API_URL=https://lawvriksh.com/api`

3. **Local Development (Frontend/.env.local):**
   - `VITE_API_URL=http://localhost:8000`

## ✅ Success Indicators

When everything is set up correctly, you should see:

1. **Database verification:**
   ```
   ✅ Admin user found in database
   ✅ Password verification successful
   ✅ Authentication service test successful
   ```

2. **Login success:**
   - Admin can login with the specified credentials
   - Admin panel is accessible
   - All admin functions work properly

## 🎯 Next Steps

1. **Deploy the updated configuration**
2. **Test admin login on production**
3. **Verify CORS is working between frontend and backend**
4. **Monitor admin access logs**

---

**Note:** Always keep the `.env` file secure and never commit it to version control. The `.gitignore` files are already configured to exclude environment files.
