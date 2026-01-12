@echo off
title Taiga Ecommerce Platform Setup

echo.
echo ^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=
echo  Taiga Multi-Vendor Ecommerce Platform Setup
echo ^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=
echo.

echo [INFO] Starting setup process...

REM Check if PHP is installed
php --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PHP is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if Composer is installed
composer --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Composer is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js is not installed or not in PATH
    pause
    exit /b 1
)

echo [SUCCESS] All prerequisites are available

echo.
echo [INFO] Setting up Laravel Backend...
cd backend

REM Copy environment file
if not exist .env (
    copy .env.example .env
    echo [SUCCESS] Environment file created
)

REM Generate application key
php artisan key:generate

REM Install packages
echo [INFO] Installing Laravel packages...
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"

echo [INFO] Running database migrations...
php artisan migrate

cd ..

echo.
echo [INFO] Setting up Next.js Website...
cd website

REM Install dependencies
npm install

REM Create environment file
if not exist .env.local (
    echo NEXT_PUBLIC_API_URL=http://localhost:8000/api > .env.local
    echo NEXT_PUBLIC_APP_URL=http://localhost:3000 >> .env.local
    echo NEXTAUTH_SECRET=your-secret-key >> .env.local
    echo NEXTAUTH_URL=http://localhost:3000 >> .env.local
    echo [SUCCESS] Environment file created for website
)

cd ..

echo.
echo [INFO] Checking Flutter installation...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Flutter is not installed. Mobile apps will need manual setup.
    echo [INFO] To setup Flutter apps:
    echo 1. Install Flutter SDK from https://flutter.dev
    echo 2. Run 'flutter pub get' in each mobile app directory
) else (
    echo [INFO] Setting up Flutter Applications...
    
    cd mobile\user_app
    flutter pub get
    cd ..\..
    
    cd mobile\seller_app
    flutter pub get
    cd ..\..
    
    cd mobile\delivery_app
    flutter pub get
    cd ..\..
    
    echo [SUCCESS] Flutter apps setup completed
)

echo.
echo ^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=
echo  Setup Completed Successfully! 
echo ^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=
echo.
echo Next steps:
echo 1. Configure your database in backend\.env
echo 2. Run backend: cd backend ^&^& php artisan serve
echo 3. Run website: cd website ^&^& npm run dev
echo 4. Setup payment gateway credentials in backend\.env
echo 5. Configure Firebase for push notifications
echo.
echo Mobile Apps:
echo * User App: cd mobile\user_app ^&^& flutter run
echo * Seller App: cd mobile\seller_app ^&^& flutter run
echo * Delivery App: cd mobile\delivery_app ^&^& flutter run
echo.
echo Access URLs:
echo * API: http://localhost:8000
echo * Website: http://localhost:3000
echo * Admin Panel: http://localhost:8000/admin
echo.
echo Happy coding! 
echo.
pause