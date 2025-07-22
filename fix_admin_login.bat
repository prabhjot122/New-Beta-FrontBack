@echo off
echo ========================================
echo LawVriksh Admin Login Fix
echo ========================================
echo.
echo This will fix the admin login credentials.
echo.
echo Current issue: Admin passwords not working
echo Solution: Update admin password hash in database
echo.
echo Choose your method:
echo 1. Quick SQL fix (recommended)
echo 2. Python script fix (more detailed)
echo.
set /p method="Enter choice (1 or 2): "

if "%method%"=="1" (
    echo.
    echo Applying SQL fix...
    echo.
    mysql -h localhost -u root -ppabbo@123 --default-character-set=utf8mb4 < fix_admin_sql.sql
    
    if %errorlevel% equ 0 (
        echo.
        echo ========================================
        echo SUCCESS: Admin login fixed!
        echo ========================================
        echo.
        echo Admin Login Credentials:
        echo Email: admin@lawvriksh.com
        echo Password: admin123
        echo.
        echo You can now login to the admin panel.
        echo.
    ) else (
        echo.
        echo ERROR: Failed to apply SQL fix
        echo Please check your MySQL connection.
        echo.
    )
) else if "%method%"=="2" (
    echo.
    echo Running Python fix script...
    echo.
    python fix_admin_password.py
) else (
    echo Invalid choice. Please run the script again.
)

pause
