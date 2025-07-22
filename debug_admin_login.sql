-- =====================================================
-- Debug Admin Login Issues
-- =====================================================
-- Run this script to check the current state of admin user
-- and verify if the password hash was updated correctly
-- =====================================================

USE lawvriksh_referral;

-- Check if the database exists and we're connected
SELECT DATABASE() as current_database;

-- Check if users table exists
SHOW TABLES LIKE 'users';

-- Check current admin users and their password hashes
SELECT 'Current Admin Users:' as section;
SELECT 
    id,
    name,
    email,
    password_hash,
    is_admin,
    is_active,
    created_at
FROM users 
WHERE email = 'admin@lawvriksh.com' OR is_admin = TRUE;

-- Check if the specific admin email exists
SELECT 'Admin Email Check:' as section;
SELECT COUNT(*) as admin_count 
FROM users 
WHERE email = 'admin@lawvriksh.com';

-- Check all users (to see if table has data)
SELECT 'All Users Count:' as section;
SELECT COUNT(*) as total_users FROM users;

-- Show first few users to verify table structure
SELECT 'Sample Users:' as section;
SELECT id, name, email, is_admin, is_active 
FROM users 
LIMIT 5;

-- Check the exact password hash for admin
SELECT 'Admin Password Hash:' as section;
SELECT 
    email,
    password_hash,
    CASE 
        WHEN password_hash = '$2b$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' 
        THEN 'CORRECT (admin123)' 
        ELSE 'INCORRECT - needs update' 
    END as hash_status
FROM users 
WHERE email = 'admin@lawvriksh.com';

-- =====================================================
-- If admin user doesn't exist or has wrong hash, 
-- run the following commands:
-- =====================================================

-- Delete existing admin if exists
-- DELETE FROM users WHERE email = 'admin@lawvriksh.com';

-- Insert correct admin user
-- INSERT INTO users (name, email, password_hash, is_admin, is_active, total_points, shares_count)
-- VALUES ('Admin User', 'admin@lawvriksh.com', '$2b$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', TRUE, TRUE, 0, 0);

SELECT 'Debug complete. Check the results above.' as status;
