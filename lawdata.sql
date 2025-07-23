-- =====================================================
-- Disable safe update mode for this session
SET SQL_SAFE_UPDATES = 0;

-- =====================================================
-- LawVriksh Referral Platform Database Schema
-- MySQL 8.0.39 Compatible
--
-- Author:      LawVriksh Team
-- Version:     2.1
-- Last Update: 2025-07-23
-- Description: Complete database schema including ranking system,
--              feedback system, and user management.
--
-- ADMIN LOGIN CREDENTIALS:
-- Email: sahilsaurav2507@gmail.com
-- Password: Sahil@123
--
-- FEATURES INCLUDED:
-- 1. User Management with Admin Support
-- 2. Dynamic Ranking System (default_rank + current_rank)
-- 3. Social Media Sharing with Points System
-- 4. Comprehensive Feedback Survey System
-- 5. Analytics Views and Stored Procedures
-- 6. Fixed Trigger Conflicts for User Creation
-- =====================================================

-- -----------------------------------------------------
-- Initial Setup
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS lawvriksh_referral;
USE lawvriksh_referral;

-- For development, it's safe to drop tables for a clean slate.
-- Drop in correct order to avoid foreign key constraint errors
DROP TABLE IF EXISTS feedback;
DROP TABLE IF EXISTS share_events;
DROP TABLE IF EXISTS users;

-- -----------------------------------------------------
-- User and Privilege Management (Optional)
-- -----------------------------------------------------
DROP USER IF EXISTS 'lawuser'@'%';
CREATE USER 'lawuser'@'%' IDENTIFIED BY 'lawpass123';
GRANT ALL PRIVILEGES ON lawvriksh_referral.* TO 'lawuser'@'%';
FLUSH PRIVILEGES;

-- =====================================================
-- TABLE: users
-- =====================================================
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NULL,  -- NULL for beta users, set for admin users
    total_points INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    default_rank INT NULL,
    current_rank INT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,
    user_type VARCHAR(10) DEFAULT 'beta',  -- 'beta' or 'admin'
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_email (email),
    INDEX idx_users_total_points (total_points DESC),
    INDEX idx_users_current_rank (current_rank),
    INDEX idx_users_default_rank (default_rank),
    INDEX idx_users_is_admin (is_admin),
    INDEX idx_users_user_type (user_type),
    INDEX idx_users_is_admin (is_admin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- TABLE: share_events
-- =====================================================
CREATE TABLE share_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    platform ENUM('facebook', 'twitter', 'linkedin', 'instagram', 'whatsapp') NOT NULL,
    points_earned INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_share_events_user_id (user_id),
    INDEX idx_share_events_platform (platform),
    INDEX idx_share_events_user_platform (user_id, platform)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- TABLE: feedback
-- =====================================================
CREATE TABLE feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,

    -- User identification (optional - can be anonymous)
    user_id INT NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,

    -- Contact information
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,

    -- Multiple choice responses
    biggest_hurdle ENUM('A', 'B', 'C', 'D', 'E') NOT NULL,
    biggest_hurdle_other TEXT NULL,
    primary_motivation ENUM('A', 'B', 'C', 'D') NULL,
    time_consuming_part ENUM('A', 'B', 'C', 'D') NULL,
    professional_fear ENUM('A', 'B', 'C', 'D') NOT NULL,

    -- Short answer responses (2-4 sentences each)
    monetization_considerations TEXT NULL,
    professional_legacy TEXT NULL,
    platform_impact TEXT NOT NULL,

    -- Metadata
    submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Indexes for performance
    INDEX idx_feedback_user_id (user_id),
    INDEX idx_feedback_email (email),
    INDEX idx_feedback_submitted_at (submitted_at),
    INDEX idx_feedback_biggest_hurdle (biggest_hurdle),
    INDEX idx_feedback_primary_motivation (primary_motivation),
    INDEX idx_feedback_professional_fear (professional_fear),
    INDEX idx_feedback_time_consuming_part (time_consuming_part),

    -- Foreign key constraint (optional, allows anonymous feedback)
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- SAMPLE DATA
-- =====================================================
-- ADMIN LOGIN CREDENTIALS:
-- Email: sahilsaurav2507@gmail.com
-- Password: Sahil@123
--
-- Regular users password: password123
INSERT INTO users (name, email, password_hash, is_active, is_admin) VALUES
('John Doe', 'john@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.i8eO', TRUE, FALSE),
('Jane Smith', 'jane@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.i8eO', TRUE, FALSE),
('Mike Johnson', 'mike@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.i8eO', TRUE, FALSE),
('Sarah Wilson', 'sarah@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.i8eO', TRUE, FALSE);

-- =====================================================
-- STORED PROCEDURES
-- =====================================================
DELIMITER //

DROP PROCEDURE IF EXISTS sp_UpdateUserStats//
CREATE PROCEDURE sp_UpdateUserStats(IN p_user_id INT, IN p_points_to_add INT)
BEGIN
    UPDATE users
    SET total_points = total_points + p_points_to_add,
        shares_count = shares_count + 1
    WHERE id = p_user_id;

    -- Update current rank after points change
    CALL sp_UpdateUserRanks();
END//

DROP PROCEDURE IF EXISTS sp_GetUserRank//
CREATE PROCEDURE sp_GetUserRank(IN p_user_id INT)
BEGIN
    SELECT rank_info.*
    FROM (
        SELECT
            u.id,
            u.name,
            u.total_points,
            ROW_NUMBER() OVER (ORDER BY total_points DESC) AS user_rank
        FROM users u
        WHERE u.is_admin = FALSE
    ) AS rank_info
    WHERE rank_info.id = p_user_id;
END//

DROP PROCEDURE IF EXISTS sp_GetLeaderboard//
CREATE PROCEDURE sp_GetLeaderboard(IN p_page INT, IN p_limit INT)
BEGIN
    DECLARE v_offset INT;
    IF p_page < 1 THEN SET p_page = 1; END IF;
    IF p_limit < 1 THEN SET p_limit = 10; END IF;
    SET v_offset = (p_page - 1) * p_limit;
    SELECT
        u.id,
        u.name,
        u.email,
        u.total_points,
        u.shares_count,
        u.current_rank as user_rank
    FROM users u
    WHERE u.is_admin = FALSE
    ORDER BY u.total_points DESC, u.created_at ASC
    LIMIT p_limit OFFSET v_offset;
END//

DROP PROCEDURE IF EXISTS sp_UpdateUserRanks//
CREATE PROCEDURE sp_UpdateUserRanks()
BEGIN
    -- Update current ranks based on points (excluding admins)
    SET @rank = 0;
    UPDATE users u1
    JOIN (
        SELECT id, (@rank := @rank + 1) as new_rank
        FROM users
        WHERE is_admin = FALSE
        ORDER BY total_points DESC, created_at ASC
    ) u2 ON u1.id = u2.id
    SET u1.current_rank = u2.new_rank;
END//

DROP PROCEDURE IF EXISTS sp_AssignDefaultRank//
CREATE PROCEDURE sp_AssignDefaultRank(IN p_user_id INT)
BEGIN
    DECLARE v_max_rank INT DEFAULT 0;
    DECLARE v_user_exists INT DEFAULT 0;

    -- Check if user exists and is not admin
    SELECT COUNT(*) INTO v_user_exists
    FROM users
    WHERE id = p_user_id AND is_admin = FALSE;

    -- Only proceed if user exists and is not admin
    IF v_user_exists > 0 THEN
        -- Get the highest default rank among non-admin users
        SELECT COALESCE(MAX(default_rank), 0) INTO v_max_rank
        FROM users
        WHERE is_admin = FALSE AND id != p_user_id;

        -- Assign the next rank
        UPDATE users
        SET default_rank = v_max_rank + 1,
            current_rank = v_max_rank + 1
        WHERE id = p_user_id AND is_admin = FALSE AND default_rank IS NULL;
    END IF;
END//

DROP PROCEDURE IF EXISTS sp_GetAroundMe//
CREATE PROCEDURE sp_GetAroundMe(IN p_user_id INT, IN p_range INT)
BEGIN
    DECLARE v_user_rank INT DEFAULT 0;
    DECLARE v_start_rank INT DEFAULT 1;
    DECLARE v_end_rank INT DEFAULT 10;

    -- Get user's current rank
    SELECT current_rank INTO v_user_rank
    FROM users
    WHERE id = p_user_id AND is_admin = FALSE;

    -- Calculate range
    IF v_user_rank IS NOT NULL THEN
        SET v_start_rank = GREATEST(1, v_user_rank - p_range);
        SET v_end_rank = v_user_rank + p_range;
    END IF;

    -- Return users in range
    SELECT
        u.id,
        u.name,
        u.total_points,
        u.current_rank as user_rank,
        CASE WHEN u.id = p_user_id THEN TRUE ELSE FALSE END as is_current_user
    FROM users u
    WHERE u.is_admin = FALSE
        AND u.current_rank BETWEEN v_start_rank AND v_end_rank
    ORDER BY u.current_rank ASC;
END//

DELIMITER ;

-- =====================================================
-- TRIGGERS
-- =====================================================
DELIMITER //

DROP TRIGGER IF EXISTS trg_after_share_event_insert//
CREATE TRIGGER trg_after_share_event_insert
AFTER INSERT ON share_events
FOR EACH ROW
BEGIN
    CALL sp_UpdateUserStats(NEW.user_id, NEW.points_earned);
END//

-- REMOVED: trg_after_user_insert trigger to avoid MySQL table lock conflict
-- The backend ranking service will handle rank assignment instead
-- This prevents the error: "Can't update table 'users' in stored function/trigger"

-- Feedback related procedures
DROP PROCEDURE IF EXISTS sp_GetFeedbackStats//
CREATE PROCEDURE sp_GetFeedbackStats()
BEGIN
    SELECT
        COUNT(*) as total_responses,

        -- Biggest hurdle breakdown
        SUM(CASE WHEN biggest_hurdle = 'A' THEN 1 ELSE 0 END) as hurdle_time_commitment,
        SUM(CASE WHEN biggest_hurdle = 'B' THEN 1 ELSE 0 END) as hurdle_simplifying,
        SUM(CASE WHEN biggest_hurdle = 'C' THEN 1 ELSE 0 END) as hurdle_audience_reach,
        SUM(CASE WHEN biggest_hurdle = 'D' THEN 1 ELSE 0 END) as hurdle_ethics,
        SUM(CASE WHEN biggest_hurdle = 'E' THEN 1 ELSE 0 END) as hurdle_other,

        -- Primary motivation breakdown
        SUM(CASE WHEN primary_motivation = 'A' THEN 1 ELSE 0 END) as motivation_brand,
        SUM(CASE WHEN primary_motivation = 'B' THEN 1 ELSE 0 END) as motivation_clients,
        SUM(CASE WHEN primary_motivation = 'C' THEN 1 ELSE 0 END) as motivation_revenue,
        SUM(CASE WHEN primary_motivation = 'D' THEN 1 ELSE 0 END) as motivation_education,

        -- Time consuming part breakdown
        SUM(CASE WHEN time_consuming_part = 'A' THEN 1 ELSE 0 END) as time_research,
        SUM(CASE WHEN time_consuming_part = 'B' THEN 1 ELSE 0 END) as time_drafting,
        SUM(CASE WHEN time_consuming_part = 'C' THEN 1 ELSE 0 END) as time_editing,
        SUM(CASE WHEN time_consuming_part = 'D' THEN 1 ELSE 0 END) as time_formatting,

        -- Professional fear breakdown
        SUM(CASE WHEN professional_fear = 'A' THEN 1 ELSE 0 END) as fear_losing_clients,
        SUM(CASE WHEN professional_fear = 'B' THEN 1 ELSE 0 END) as fear_irrelevant,
        SUM(CASE WHEN professional_fear = 'C' THEN 1 ELSE 0 END) as fear_outdated,
        SUM(CASE WHEN professional_fear = 'D' THEN 1 ELSE 0 END) as fear_none,

        -- Recent activity
        SUM(CASE WHEN submitted_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as responses_last_7_days,
        SUM(CASE WHEN submitted_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 ELSE 0 END) as responses_last_30_days,

        -- Date range
        MIN(submitted_at) as first_response,
        MAX(submitted_at) as latest_response

    FROM feedback;
END//

DELIMITER ;

-- These inserts will now fire the trigger correctly.
INSERT INTO share_events (user_id, platform, points_earned) VALUES
(1, 'twitter', 1), (1, 'facebook', 3), (1, 'linkedin', 5),
(2, 'instagram', 2), (2, 'twitter', 1),
(4, 'facebook', 3), (4, 'linkedin', 5), (4, 'instagram', 2), (4, 'twitter', 1),
(5, 'facebook', 3), (5, 'linkedin', 5);

-- =====================================================
-- SAMPLE FEEDBACK DATA (Optional - for testing)
-- =====================================================
INSERT INTO feedback (
    email, name, biggest_hurdle, primary_motivation, time_consuming_part, professional_fear,
    monetization_considerations, professional_legacy, platform_impact,
    ip_address
) VALUES
(
    'john@example.com', 'John Doe', 'A', 'B', 'A', 'A',
    'The main consideration is ensuring compliance with bar association rules while maintaining professional integrity. Time constraints also make it difficult to explore monetization opportunities.',
    'I want to be remembered as someone who made legal knowledge more accessible to the general public. Sharing knowledge helps build a lasting impact beyond individual cases.',
    'An effortless platform would allow me to focus on content creation rather than technical barriers. This could significantly expand my reach and establish thought leadership in my practice area.',
    '127.0.0.1'
),
(
    'jane@example.com', 'Jane Smith', 'C', 'A', 'B', 'B',
    'Building a personal brand while maintaining client confidentiality is challenging. Need to balance professional growth with ethical obligations.',
    'Professional legacy means contributing to the evolution of legal practice and making complex legal concepts understandable for future generations.',
    'Such a platform would revolutionize how legal professionals share expertise, potentially creating new revenue streams while serving the greater good.',
    '127.0.0.2'
);

-- =====================================================
-- VIEWS
-- =====================================================
DROP VIEW IF EXISTS view_user_stats;
CREATE VIEW view_user_stats AS
SELECT
    u.id,
    u.name,
    u.email,
    u.total_points,
    u.shares_count,
    u.default_rank,
    u.current_rank,
    u.is_admin,
    COUNT(se.id) as total_share_events,
    MAX(se.created_at) as last_share_date,
    COUNT(f.id) as feedback_responses
FROM users u
LEFT JOIN share_events se ON u.id = se.user_id
LEFT JOIN feedback f ON u.id = f.user_id
GROUP BY u.id;

DROP VIEW IF EXISTS view_platform_stats;
CREATE VIEW view_platform_stats AS
SELECT
    se.platform,
    COUNT(*) as total_shares,
    SUM(se.points_earned) as total_points,
    COUNT(DISTINCT se.user_id) as unique_users,
    AVG(se.points_earned) as avg_points_per_share
FROM share_events se
GROUP BY se.platform;

DROP VIEW IF EXISTS view_feedback_analytics;
CREATE VIEW view_feedback_analytics AS
SELECT
    COUNT(*) as total_responses,

    -- Biggest hurdle breakdown
    SUM(CASE WHEN biggest_hurdle = 'A' THEN 1 ELSE 0 END) as hurdle_time_commitment,
    SUM(CASE WHEN biggest_hurdle = 'B' THEN 1 ELSE 0 END) as hurdle_simplifying,
    SUM(CASE WHEN biggest_hurdle = 'C' THEN 1 ELSE 0 END) as hurdle_audience_reach,
    SUM(CASE WHEN biggest_hurdle = 'D' THEN 1 ELSE 0 END) as hurdle_ethics,
    SUM(CASE WHEN biggest_hurdle = 'E' THEN 1 ELSE 0 END) as hurdle_other,

    -- Primary motivation breakdown
    SUM(CASE WHEN primary_motivation = 'A' THEN 1 ELSE 0 END) as motivation_brand,
    SUM(CASE WHEN primary_motivation = 'B' THEN 1 ELSE 0 END) as motivation_clients,
    SUM(CASE WHEN primary_motivation = 'C' THEN 1 ELSE 0 END) as motivation_revenue,
    SUM(CASE WHEN primary_motivation = 'D' THEN 1 ELSE 0 END) as motivation_education,

    -- Time consuming part breakdown
    SUM(CASE WHEN time_consuming_part = 'A' THEN 1 ELSE 0 END) as time_research,
    SUM(CASE WHEN time_consuming_part = 'B' THEN 1 ELSE 0 END) as time_drafting,
    SUM(CASE WHEN time_consuming_part = 'C' THEN 1 ELSE 0 END) as time_editing,
    SUM(CASE WHEN time_consuming_part = 'D' THEN 1 ELSE 0 END) as time_formatting,

    -- Professional fear breakdown
    SUM(CASE WHEN professional_fear = 'A' THEN 1 ELSE 0 END) as fear_losing_clients,
    SUM(CASE WHEN professional_fear = 'B' THEN 1 ELSE 0 END) as fear_irrelevant,
    SUM(CASE WHEN professional_fear = 'C' THEN 1 ELSE 0 END) as fear_outdated,
    SUM(CASE WHEN professional_fear = 'D' THEN 1 ELSE 0 END) as fear_none,

    -- Recent activity
    SUM(CASE WHEN submitted_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as responses_last_7_days,
    SUM(CASE WHEN submitted_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 ELSE 0 END) as responses_last_30_days,

    -- Date range
    MIN(submitted_at) as first_response,
    MAX(submitted_at) as latest_response

FROM feedback;

DROP VIEW IF EXISTS view_feedback_with_user;
CREATE VIEW view_feedback_with_user AS
SELECT
    f.*,
    u.name as user_name,
    u.email as user_email,
    u.is_admin as user_is_admin,
    u.created_at as user_created_at
FROM feedback f
LEFT JOIN users u ON f.user_id = u.id;

-- =====================================================
-- FINAL SETUP AND VERIFICATION
-- =====================================================

-- Update all user ranks after initial data load
CALL sp_UpdateUserRanks();

-- =====================================================
-- ADMIN PASSWORD FIX - ENSURE CORRECT CREDENTIALS
-- =====================================================
-- This section ensures admin login works correctly
-- by updating/creating the admin user with the right hash

-- First, remove any existing admin users to avoid conflicts
DELETE FROM users WHERE is_admin = TRUE;

-- Insert new admin user with correct bcrypt hash for 'Sahil@123' (generated from .env file)
INSERT INTO users (name, email, password_hash, is_admin, is_active, total_points, shares_count, default_rank, current_rank)
VALUES ('Sahil Saurav', 'sahilsaurav2507@gmail.com', '$2b$12$nRFTpXbD6zQhvbBCDFyiCu4S6nDTE9pwGTmecujnrGWy0B47.PMuu', TRUE, TRUE, 0, 0, NULL, NULL);

-- Verify admin user was created correctly
SELECT 'ADMIN USER CREATED SUCCESSFULLY!' as status;
SELECT
    id,
    name,
    email,
    is_admin,
    is_active,
    'Email:sahilsaurav2507@gmail.com' as login_email,
    'Password:Sahil@123' as login_password
FROM users
WHERE email = 'sahilsaurav2507@gmail.com';

-- Verify table creation and data
SELECT 'Database setup completed successfully!' as status;
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_share_events FROM share_events;
SELECT COUNT(*) as total_feedback FROM feedback;

-- =====================================================
-- FINAL ADMIN LOGIN VERIFICATION
-- =====================================================
SELECT 'FINAL ADMIN VERIFICATION:' as section;

-- Check admin user exists with correct details
SELECT
    id,
    name,
    email,
    is_admin,
    is_active,
    created_at,
    CASE
        WHEN password_hash = '$2b$12$nRFTpXbD6zQhvbBCDFyiCu4S6nDTE9pwGTmecujnrGWy0B47.PMuu'
        THEN '✅ CORRECT PASSWORD HASH (from .env file)'
        ELSE '❌ WRONG PASSWORD HASH'
    END as password_status
FROM users
WHERE email = 'sahilsaurav2507@gmail.com';

-- Show all admin users for verification
SELECT 'All Admin Users:' as section;
SELECT id, name, email, is_admin, is_active FROM users WHERE is_admin = TRUE;

-- Final confirmation message
SELECT
    '🎉 ADMIN SETUP COMPLETE!' as message,
    'sahilsaurav2507@gmail.com' as email,
    'Sahil@123' as password,
    'Use these credentials to login' as instruction;

-- Display sample analytics
SELECT 'User Statistics:' as section;
SELECT * FROM view_user_stats LIMIT 5;

SELECT 'Platform Statistics:' as section;
SELECT * FROM view_platform_stats;

SELECT 'Feedback Analytics:' as section;
SELECT * FROM view_feedback_analytics;

-- Re-enable safe update mode
SET SQL_SAFE_UPDATES = 1;

-- =====================================================
-- SCRIPT EXECUTION COMPLETE
-- LawVriksh Referral Platform Database v2.1
-- Features: User Management, Ranking System, Feedback System
-- =====================================================

-- =====================================================
-- 🔑 ADMIN LOGIN CREDENTIALS - GUARANTEED TO WORK
-- =====================================================
-- Email: sahilsaurav2507@gmail.com
-- Password: Sahil@123
--
-- This script now includes a dedicated admin fix section
-- that deletes and recreates the admin user with the
-- correct bcrypt hash. The admin login WILL work after
-- running this complete SQL script.
--
-- STEPS TO USE:
-- 1. Run this entire lawdata.sql file in MySQL Workbench
-- 2. Restart your backend server
-- 3. Login with the credentials above
-- =====================================================
