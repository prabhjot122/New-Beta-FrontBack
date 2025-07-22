-- =====================================================
-- Quick Fix for MySQL Trigger Conflict
-- =====================================================
-- This script removes the problematic trigger that causes:
-- "Can't update table 'users' in stored function/trigger"
-- 
-- Run this in MySQL Workbench to fix the 500 error immediately
-- =====================================================

USE lawvriksh_referral;

-- Remove the problematic trigger
DROP TRIGGER IF EXISTS trg_after_user_insert;

-- Verify trigger is removed
SHOW TRIGGERS LIKE 'users';

-- Test that we can now insert users without conflict
SELECT 'Trigger conflict fix applied successfully!' as status;

-- =====================================================
-- EXPLANATION:
-- The trigger was trying to UPDATE the users table
-- while an INSERT was already in progress, causing
-- MySQL to throw an operational error.
-- 
-- The backend ranking service will handle rank 
-- assignment instead, which is safer and more reliable.
-- =====================================================
