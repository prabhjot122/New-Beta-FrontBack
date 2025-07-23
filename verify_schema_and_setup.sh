#!/bin/bash

echo "🔍 Schema Verification and Complete Setup"
echo "=========================================="

cd ~/New-Beta-FrontBack

# Step 1: Update database schema
echo "1️⃣ Updating database schema..."
docker-compose exec mysql mysql -u root -pSahil123 << 'SQL_EOF'
USE lawvriksh_referral;

-- Disable foreign key checks
SET FOREIGN_KEY_CHECKS = 0;

-- Drop all tables
DROP TABLE IF EXISTS shares;
DROP TABLE IF EXISTS feedback;
DROP TABLE IF EXISTS campaigns;
DROP TABLE IF EXISTS users;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Create users table with correct schema matching the code
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NULL,  -- NULL for beta users, set for admin
    total_points INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    default_rank INT NULL,
    current_rank INT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,
    user_type VARCHAR(10) DEFAULT 'beta',  -- 'beta' or 'admin'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_total_points (total_points DESC),
    INDEX idx_is_admin (is_admin),
    INDEX idx_user_type (user_type)
);

-- Create other tables
CREATE TABLE shares (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    platform VARCHAR(50) NOT NULL,
    points_earned INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_platform (platform)
);

CREATE TABLE campaigns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    message TEXT NOT NULL,
    rating INT DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id)
);

-- Verify schema
DESCRIBE users;
SQL_EOF

echo "✅ Database schema updated"

# Step 2: Restart backend to load new models
echo "2️⃣ Restarting backend..."
docker-compose restart backend
sleep 30

# Step 3: Setup admin user
echo "3️⃣ Setting up admin user..."
docker cp setup_admin_corrected.py $(docker-compose ps -q backend):/app/
docker-compose exec backend python setup_admin_corrected.py

# Step 4: Test beta registration (no password)
echo "4️⃣ Testing beta registration (no password)..."
curl -X POST http://localhost:8000/beta/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Beta User","email":"beta@test.com"}'

echo ""

# Step 5: Test admin login (with password)
echo "5️⃣ Testing admin login (with password)..."
curl -X POST http://localhost:8000/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sahilsaurav2507@gmail.com","password":"Sahil@123"}'

echo ""

# Step 6: Verify database contents
echo "6️⃣ Verifying database contents..."
docker-compose exec mysql mysql -u root -pSahil123 -e "
USE lawvriksh_referral;
SELECT 
    CONCAT('👤 ', name) as user_name,
    email,
    user_type,
    CASE WHEN is_admin THEN '👑 Admin' ELSE '🎯 Beta' END as role,
    CASE WHEN password_hash IS NOT NULL THEN '🔐 Has Password' ELSE '📧 Email Only' END as auth_method,
    created_at
FROM users
ORDER BY created_at;
"

echo ""
echo "🎉 Setup complete!"
echo "📝 Beta users: Name + Email only (no password)"
echo "🔐 Admin users: Email + Password authentication"
