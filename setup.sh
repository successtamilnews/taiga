#!/bin/bash

# Taiga Ecommerce Platform Setup Script
# This script sets up the complete development environment

echo "🚀 Setting up Taiga Multi-Vendor Ecommerce Platform..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running on Windows (Git Bash)
if [[ "$OSTYPE" == "msys" ]]; then
    echo "📟 Detected Windows environment"
    PHP_CMD="php"
    NPM_CMD="npm"
    COMPOSER_CMD="composer"
else
    echo "🐧 Detected Unix-like environment"
    PHP_CMD="php"
    NPM_CMD="npm"
    COMPOSER_CMD="composer"
fi

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check PHP
    if ! command -v $PHP_CMD &> /dev/null; then
        print_error "PHP is not installed or not in PATH"
        exit 1
    fi
    
    # Check Composer
    if ! command -v $COMPOSER_CMD &> /dev/null; then
        print_error "Composer is not installed or not in PATH"
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed or not in PATH"
        exit 1
    fi
    
    # Check npm
    if ! command -v $NPM_CMD &> /dev/null; then
        print_error "npm is not installed or not in PATH"
        exit 1
    fi
    
    # Check Flutter (optional)
    if ! command -v flutter &> /dev/null; then
        print_warning "Flutter is not installed. Mobile apps will need manual setup."
    fi
    
    print_success "All prerequisites are available"
}

# Setup Laravel Backend
setup_backend() {
    print_status "Setting up Laravel Backend..."
    
    cd backend || exit
    
    # Copy environment file
    if [[ ! -f .env ]]; then
        cp .env.example .env
        print_success "Environment file created"
    fi
    
    # Generate application key
    $PHP_CMD artisan key:generate
    
    # Install Sanctum
    $PHP_CMD artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
    
    # Install Spatie Permission
    $PHP_CMD artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
    
    # Run migrations
    print_status "Running database migrations..."
    $PHP_CMD artisan migrate:fresh --seed
    
    print_success "Laravel backend setup completed"
    cd ..
}

# Setup Next.js Website
setup_website() {
    print_status "Setting up Next.js Website..."
    
    cd website || exit
    
    # Install dependencies
    $NPM_CMD install
    
    # Copy environment file
    if [[ ! -f .env.local ]]; then
        cat > .env.local << EOL
NEXT_PUBLIC_API_URL=http://localhost:8000/api
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key
NEXTAUTH_URL=http://localhost:3000
EOL
        print_success "Environment file created for website"
    fi
    
    print_success "Next.js website setup completed"
    cd ..
}

# Setup Flutter Apps
setup_flutter_apps() {
    if command -v flutter &> /dev/null; then
        print_status "Setting up Flutter Applications..."
        
        # User App
        cd mobile/user_app || exit
        flutter pub get
        cd ../..
        
        # Seller App
        cd mobile/seller_app || exit
        flutter pub get
        cd ../..
        
        # Delivery App
        cd mobile/delivery_app || exit
        flutter pub get
        cd ../..
        
        print_success "Flutter apps setup completed"
    else
        print_warning "Flutter not found. Skipping mobile apps setup."
        print_status "To setup Flutter apps manually:"
        print_status "1. Install Flutter SDK from https://flutter.dev"
        print_status "2. Run 'flutter pub get' in each mobile app directory"
    fi
}

# Create database
setup_database() {
    print_status "Database setup instructions:"
    echo "1. Create a MySQL database named 'taiga_ecommerce'"
    echo "2. Update database credentials in backend/.env file"
    echo "3. Run: cd backend && php artisan migrate:fresh --seed"
    echo ""
}

# Display completion message
show_completion_message() {
    echo ""
    print_success "🎉 Taiga Ecommerce Platform setup completed!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Configure your database in backend/.env"
    echo "2. Run backend: cd backend && php artisan serve"
    echo "3. Run website: cd website && npm run dev"
    echo "4. Setup payment gateway credentials in backend/.env"
    echo "5. Configure Firebase for push notifications"
    echo ""
    echo "📱 Mobile Apps:"
    echo "• User App: cd mobile/user_app && flutter run"
    echo "• Seller App: cd mobile/seller_app && flutter run"  
    echo "• Delivery App: cd mobile/delivery_app && flutter run"
    echo ""
    echo "🌐 Access URLs:"
    echo "• API: http://localhost:8000"
    echo "• Website: http://localhost:3000"
    echo "• Admin Panel: http://localhost:8000/admin"
    echo ""
    print_success "Happy coding! 🚀"
}

# Main execution
main() {
    echo "🏗️  Taiga Multi-Vendor Ecommerce Platform Setup"
    echo "=============================================="
    echo ""
    
    check_prerequisites
    setup_backend
    setup_website
    setup_flutter_apps
    setup_database
    show_completion_message
}

# Run main function
main