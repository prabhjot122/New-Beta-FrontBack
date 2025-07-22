@echo off
echo ========================================
echo LawVriksh Database Schema Update
echo ========================================
echo.

REM Check if lawdata.sql exists
if not exist "lawdata.sql" (
    echo ERROR: lawdata.sql file not found!
    echo Please make sure you're running this from the BetajoiningBackend directory.
    pause
    exit /b 1
)

REM Check if .env file exists
if not exist ".env" (
    echo ERROR: .env file not found!
    echo Please create a .env file with your database credentials.
    pause
    exit /b 1
)

echo Found lawdata.sql and .env files.
echo.
echo This will update your database schema with the latest changes.
echo WARNING: This will drop and recreate tables!
echo.
set /p confirm="Continue? (y/N): "
if /i not "%confirm%"=="y" if /i not "%confirm%"=="yes" (
    echo Operation cancelled.
    pause
    exit /b 0
)

echo.
echo Applying database schema...
echo.

REM Apply the SQL file using MySQL command line
REM Note: You may need to adjust the MySQL path if it's not in your PATH
mysql -h localhost -u root -ppabbo@123 --default-character-set=utf8mb4 < lawdata.sql

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo SUCCESS: Database schema updated!
    echo ========================================
    echo.
    echo Next steps:
    echo 1. Restart your backend server
    echo 2. Test the signup functionality
    echo.
) else (
    echo.
    echo ========================================
    echo ERROR: Failed to update database schema
    echo ========================================
    echo.
    echo Troubleshooting:
    echo 1. Check if MySQL server is running
    echo 2. Verify database credentials
    echo 3. Ensure MySQL client is installed and in PATH
    echo.
)

pause
