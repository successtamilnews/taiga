@echo off
echo Starting Taiga Backend Setup...

cd /d "c:\Users\dilee\Downloads\cp\taiga\backend"

echo Installing Composer dependencies...
call composer install --no-interaction
if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to install Composer dependencies
    exit /b 1
)

echo Setting up environment file...
if not exist .env (
    copy .env.example .env
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Failed to copy environment file
        exit /b 1
    )
)

echo Generating application key...
call php artisan key:generate
if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to generate application key
    exit /b 1
)

echo Creating storage and cache directories...
mkdir "storage\logs\analytics" 2>nul
mkdir "storage\logs\websocket" 2>nul
mkdir "storage\logs\performance" 2>nul

echo Clearing cache and config...
call php artisan config:clear
call php artisan cache:clear

echo Running migrations...
call php artisan migrate --force
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Some migrations may have failed
)

echo Setup completed successfully!
echo Next steps:
echo 1. Configure your .env file with database credentials
echo 2. Run 'php artisan config:validate' to check configuration
echo 3. Start the WebSocket server with 'php artisan websocket:serve'
echo 4. Start queue workers with 'php artisan queue:work'