@echo off
echo ========================================
echo LawVriksh 500 Error Quick Fix
echo ========================================
echo.
echo This will remove the problematic MySQL trigger
echo that's causing the signup 500 error.
echo.
echo Error: "Can't update table 'users' in stored function/trigger"
echo.
set /p confirm="Apply fix? (y/N): "
if /i not "%confirm%"=="y" if /i not "%confirm%"=="yes" (
    echo Operation cancelled.
    pause
    exit /b 0
)

echo.
echo Applying trigger fix...
echo.

REM Apply the trigger fix
mysql -h localhost -u root -ppabbo@123 --default-character-set=utf8mb4 < fix_trigger_conflict.sql

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo SUCCESS: Trigger conflict fixed!
    echo ========================================
    echo.
    echo The problematic trigger has been removed.
    echo Backend ranking service will handle user ranks.
    echo.
    echo Next steps:
    echo 1. Restart your backend server
    echo 2. Test signup functionality
    echo.
) else (
    echo.
    echo ========================================
    echo ERROR: Failed to apply fix
    echo ========================================
    echo.
    echo Please check:
    echo 1. MySQL server is running
    echo 2. Database credentials are correct
    echo 3. Database 'lawvriksh_referral' exists
    echo.
)

pause
