# Taiga Multi-Vendor Ecommerce Platform

A comprehensive multi-vendor ecommerce platform featuring Laravel PHP backend, Flutter mobile apps, Next.js website, and POS system.

## 🏗️ Project Structure

```
taiga/
├── backend/                     # Laravel PHP Backend (Admin Panel & APIs)
│   ├── app/Models/              # Eloquent Models
│   ├── app/Http/Controllers/    # API Controllers
│   ├── database/migrations/     # Database Migrations
│   ├── routes/api.php          # API Routes
│   └── config/                 # Configuration Files
├── mobile/                     # Flutter Mobile Applications
│   ├── user_app/              # Customer Mobile App
│   ├── seller_app/            # Vendor/Seller Mobile App
│   └── delivery_app/          # Delivery Personnel App
├── website/                   # Next.js Website Frontend
│   ├── src/                   # Source Code
│   ├── public/                # Static Assets
│   └── components/            # React Components
├── pos/                       # Point of Sale System
└── docs/                      # Documentation
```

## 🚀 Features

### 🔐 Authentication & User Management
- Admin Panel with role-based access control
- Seller/Vendor registration and verification
- Customer account management
- Delivery personnel management
- Employee & User Settings

### 🛍️ Product Management
- Physical & Digital Products
- Multi-vendor product catalog
- Category & subcategory management
- Inventory tracking
- Product variants (size, color, etc.)
- Bulk product import/export

### 📦 Order Management
- Dynamic order processing
- Real-time order tracking
- Order status updates
- Return & refund management
- Automated notifications

### 🚚 Delivery Management
- Delivery person assignment
- Real-time tracking with GPS
- Delivery route optimization
- Proof of delivery
- Delivery analytics

### 💰 Payment Integration
- Google Pay
- Apple Pay
- Sampath Bank Sri Lanka IPG
- Multiple payment methods
- Secure payment processing
- Wallet system

### 🎯 Marketing & Promotions
- Coupons & Discount codes
- Loyalty points system
- Banner announcements
- Email marketing
- Push notifications

### 📊 Analytics & Reporting
- Sales reports
- Vendor performance analytics
- Customer analytics
- Inventory reports
- Revenue tracking
- Live charts & dashboards

### 🌐 Multi-Language & Multi-Currency
- Support for multiple languages
- Multiple currency handling
- Regional customization
- Localized content

### 🏪 Store & Brand Management
- Multi-vendor support
- Store supervision
- Brand management
- Seller commission tracking
- Performance monitoring

### 🛒 POS System
- In-store sales processing
- Inventory management
- Receipt printing
- Staff management

### 🔍 SEO & Performance
- SEO-friendly website
- Fast loading times
- Mobile responsive design
- Search engine optimization

## 🛠️ Technology Stack

### Backend (Laravel PHP)
- **Framework**: Laravel 11.x
- **Database**: MySQL/PostgreSQL
- **Authentication**: Laravel Sanctum
- **Permissions**: Spatie Laravel Permission
- **Image Processing**: Intervention Image
- **Real-time**: Pusher
- **Payment**: Laravel Cashier

### Frontend (Next.js)
- **Framework**: Next.js 14
- **Styling**: Tailwind CSS
- **Language**: TypeScript
- **State Management**: Redux Toolkit / Zustand
- **UI Components**: Radix UI / Shadcn

### Mobile Apps (Flutter)
- **Framework**: Flutter
- **State Management**: Provider / BLoC
- **Networking**: Dio
- **Local Storage**: SharedPreferences, SQLite
- **Push Notifications**: Firebase Messaging
- **Maps**: Google Maps
- **Payments**: Google Pay, Apple Pay

## 📋 Prerequisites

- PHP 8.2 or higher
- Composer
- Node.js 18+ and npm
- Flutter SDK 3.0+
- MySQL 8.0+ or PostgreSQL
- Firebase Project (for notifications)
- Google Maps API Key
- Payment Gateway credentials

## ⚡ Quick Start

### 1. Backend Setup (Laravel)

```bash
# Navigate to backend directory
cd backend

# Install dependencies
composer install

# Set up environment
cp .env.example .env
php artisan key:generate

# Configure database in .env file
php artisan migrate

# Seed database
php artisan db:seed

# Install Laravel packages
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

# Start development server
php artisan serve
```

### 2. Website Setup (Next.js)

```bash
# Navigate to website directory
cd website

# Install dependencies
npm install

# Set up environment variables
cp .env.local.example .env.local

# Start development server
npm run dev
```

### 3. Mobile Apps Setup (Flutter)

**Prerequisites**: Install Flutter SDK from [flutter.dev](https://flutter.dev)

```bash
# User App
cd mobile/user_app
flutter pub get
flutter run

# Seller App
cd mobile/seller_app
flutter pub get
flutter run

# Delivery App
cd mobile/delivery_app
flutter pub get
flutter run
```

### 4. POS System Setup

```bash
# Navigate to POS directory
cd pos

# Follow POS-specific setup instructions
# (Will be created based on chosen POS technology)
```

## 🔧 Configuration

### Database Configuration
Configure your database connection in `backend/.env`:
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=taiga_ecommerce
DB_USERNAME=root
DB_PASSWORD=
```

### Payment Gateway Configuration
Add your payment gateway credentials to `backend/.env`:
```env
# Google Pay
GOOGLE_PAY_MERCHANT_ID=your_merchant_id

# Apple Pay
APPLE_PAY_MERCHANT_ID=your_merchant_id

# Sampath Bank Sri Lanka
SAMPATH_MERCHANT_ID=your_merchant_id
SAMPATH_API_KEY=your_api_key
```

### Firebase Configuration
1. Create a Firebase project
2. Download configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
   - Web config for Next.js
3. Configure Firebase in each app

### Maps Configuration
Add Google Maps API key to environment files:
```env
GOOGLE_MAPS_API_KEY=your_api_key
```

## 📱 Mobile App Features

### User App
- Browse products by category
- Search and filter products
- Add to cart and wishlist
- Secure checkout process
- Order tracking
- User profile management
- Push notifications
- Reviews and ratings

### Seller App
- Product management
- Order management
- Sales analytics
- Inventory tracking
- Customer communication
- Performance dashboard
- Commission tracking

### Delivery App
- Order assignment
- GPS navigation
- Delivery status updates
- Proof of delivery
- Earnings tracking
- Route optimization

## 🌐 API Documentation

The backend provides RESTful APIs for all mobile and web applications:

- **Authentication**: `/api/auth/*`
- **Products**: `/api/products/*`
- **Orders**: `/api/orders/*`
- **Vendors**: `/api/vendors/*`
- **Payments**: `/api/payments/*`
- **Admin**: `/api/admin/*`

API documentation available at `/api/documentation` when backend is running.

## 🚀 Deployment

### Backend Deployment
1. Configure production environment
2. Set up SSL certificate
3. Configure web server (Nginx/Apache)
4. Set up queue workers
5. Configure cron jobs for Laravel scheduler

### Frontend Deployment
1. Build production assets: `npm run build`
2. Deploy to hosting service (Vercel, Netlify, etc.)

### Mobile Apps Deployment
1. Build release APK/AAB for Android
2. Build IPA for iOS App Store
3. Submit to respective app stores

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## 🆘 Support

For support and questions:
- Email: support@taiga-ecommerce.com
- Documentation: [docs.taiga-ecommerce.com](https://docs.taiga-ecommerce.com)
- Issues: [GitHub Issues](https://github.com/taiga-ecommerce/issues)

## 🎯 Roadmap

- [ ] AI-powered product recommendations
- [ ] Advanced analytics dashboard
- [ ] Multi-warehouse management
- [ ] Subscription commerce features
- [ ] Social commerce integration
- [ ] Advanced SEO features
- [ ] Progressive Web App (PWA)
- [ ] Voice commerce integration

---

**Built with ❤️ by the Taiga Team**