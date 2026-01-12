@echo off
echo Setting up Taiga Ecommerce Backend...

cd /d "%~dp0backend"

echo Installing Composer dependencies...
composer install --no-interaction --optimize-autoloader

echo Copying environment file...
if exist .env.example (
    copy .env.example .env
) else (
    echo .env.example file not found!
    pause
    exit /b 1
)

echo Generating application key...
php artisan key:generate

echo Setting up database...
php artisan migrate:fresh --seed

echo Publishing Sanctum configuration...
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

echo Publishing Spatie Permission configuration...
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"

echo Clearing caches...
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo Creating storage link...
php artisan storage:link

echo Running seeders...
php artisan db:seed --class=EcommerceSeeder

echo Backend setup completed successfully!
echo.
echo You can now start the Laravel development server with:
echo php artisan serve --host=0.0.0.0 --port=8000
echo.
pause