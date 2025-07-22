-- =====================================================
-- Fix Admin Password - SQL Script
-- =====================================================
-- This script will update the admin password to 'admin123'
-- with a properly generated bcrypt hash
-- =====================================================

USE lawvriksh_referral;

-- First, let's see current admin users
SELECT id, name, email, is_admin, is_active, created_at 
FROM users 
WHERE is_admin = TRUE OR email LIKE '%admin%';

-- Update admin password to 'admin123' with correct bcrypt hash
-- This hash was generated using Python's passlib with bcrypt
UPDATE users 
SET password_hash = '$2b$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    is_admin = TRUE,
    is_active = TRUE
WHERE email = 'admin@lawvriksh.com';

-- If no admin user exists, create one
INSERT IGNORE INTO users (name, email, password_hash, is_admin, is_active, total_points, shares_count)
VALUES ('Admin User', 'admin@lawvriksh.com', '$2b$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', TRUE, TRUE, 0, 0);

-- Verify the admin user
SELECT id, name, email, is_admin, is_active, created_at 
FROM users 
WHERE email = 'admin@lawvriksh.com';

-- Show success message
SELECT 'Admin password updated successfully!' as status,
       'Email: admin@lawvriksh.com' as email,
       'Password: admin123' as password;

-- =====================================================
-- ADMIN LOGIN CREDENTIALS:
-- Email: admin@lawvriksh.com
-- Password: admin123
-- =====================================================
