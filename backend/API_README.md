# Taiga Ecommerce Backend

A comprehensive Laravel-based backend for a multi-vendor ecommerce platform with API endpoints, admin panel, and payment gateway integrations.

## Features

- **Multi-vendor Support**: Complete vendor management system
- **RESTful API**: Comprehensive API endpoints for frontend integration
- **Authentication**: JWT-based authentication with Laravel Sanctum
- **Payment Gateways**: Google Pay, Apple Pay, Sampath Bank IPG
- **Product Management**: Full product catalog with images, attributes, reviews
- **Order Management**: Complete order lifecycle management
- **User Management**: Roles and permissions with Spatie Laravel Permission
- **Analytics**: Performance monitoring and logging system
- **WebSocket Support**: Real-time notifications

## Tech Stack

- **Framework**: Laravel 11.31
- **Authentication**: Laravel Sanctum
- **Authorization**: Spatie Laravel Permission
- **Image Processing**: Intervention Image
- **WebSockets**: Ratchet/Pusher
- **Database**: MySQL
- **Queue**: Redis (optional)

## Installation

### Prerequisites

- PHP 8.2 or higher
- Composer
- MySQL 8.0 or higher
- Node.js (for asset compilation)

### Quick Setup

1. **Clone and Navigate**:
   ```bash
   cd backend
   ```

2. **Install Dependencies**:
   ```bash
   composer install
   ```

3. **Environment Setup**:
   ```bash
   cp .env.example .env
   ```

4. **Configure Database** (edit `.env`):
   ```env
   DB_DATABASE=taiga_ecommerce
   DB_USERNAME=root
   DB_PASSWORD=your_password
   ```

5. **Generate Keys and Setup Database**:
   ```bash
   php artisan key:generate
   php artisan migrate:fresh --seed
   ```

6. **Start Development Server**:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```

### Windows Quick Setup

Run the automated setup script:
```bash
..\setup-backend.bat
```

## API Endpoints

### Authentication
- `POST /api/v1/register` - User registration
- `POST /api/v1/login` - User login
- `POST /api/v1/logout` - User logout
- `GET /api/v1/profile` - Get user profile
- `PUT /api/v1/profile` - Update user profile

### Products
- `GET /api/v1/products` - List products with filtering
- `GET /api/v1/products/featured` - Get featured products
- `GET /api/v1/products/{id}` - Get single product
- `GET /api/v1/products/{id}/related` - Get related products
- `GET /api/v1/products/{id}/reviews` - Get product reviews

### Categories
- `GET /api/v1/categories` - List categories
- `GET /api/v1/categories/{id}` - Get category details
- `GET /api/v1/categories/{id}/products` - Get category products

### Orders
- `GET /api/v1/orders` - Get user orders
- `POST /api/v1/orders` - Create new order
- `GET /api/v1/orders/{id}` - Get order details
- `POST /api/v1/orders/{id}/cancel` - Cancel order

### Wishlist
- `GET /api/v1/wishlist` - Get user wishlist
- `POST /api/v1/wishlist` - Add to wishlist
- `DELETE /api/v1/wishlist/{productId}` - Remove from wishlist

### Shipping Addresses
- `GET /api/v1/shipping-addresses` - Get user addresses
- `POST /api/v1/shipping-addresses` - Create new address
- `PUT /api/v1/shipping-addresses/{id}` - Update address
- `DELETE /api/v1/shipping-addresses/{id}` - Delete address

## Database Schema

### Core Tables
- `users` - User accounts (customers, vendors, admins)
- `vendors` - Vendor business information
- `categories` - Product categories (hierarchical)
- `products` - Product catalog
- `product_images` - Product image gallery
- `product_attributes` - Product specifications
- `product_reviews` - Customer reviews and ratings

### Order Management
- `orders` - Order information
- `order_items` - Individual order line items
- `payments` - Payment records
- `shipping_addresses` - Customer addresses

### Additional Features
- `wishlist_items` - Customer wishlists
- `coupons` - Discount coupons
- `wallets` - Vendor earnings tracking

## Default Users

After running the seeder:

| Role | Email | Password | Access |
|------|-------|----------|--------|
| Admin | admin@taiga.com | password | Full system access |
| Vendor | vendor@taiga.com | password | Vendor dashboard |
| Customer | customer@taiga.com | password | Shopping features |

## Payment Gateway Configuration

### Google Pay
```env
GOOGLE_PAY_MERCHANT_ID=your_merchant_id
GOOGLE_PAY_ENVIRONMENT=TEST
```

### Apple Pay
```env
APPLE_PAY_MERCHANT_ID=your_merchant_id
APPLE_PAY_DISPLAY_NAME="Taiga Store"
```

### Sampath Bank IPG (Sri Lanka)
```env
SAMPATH_IPG_MERCHANT_ID=your_merchant_id
SAMPATH_IPG_SECRET_KEY=your_secret_key
SAMPATH_IPG_ENVIRONMENT=TEST
```

## API Authentication

The API uses Laravel Sanctum for authentication. Include the token in requests:

```bash
Authorization: Bearer {token}
```

## Error Handling

All API responses follow a consistent format:

**Success Response:**
```json
{
    "status": "success",
    "data": {...},
    "message": "Optional message"
}
```

**Error Response:**
```json
{
    "status": "error",
    "message": "Error description",
    "errors": {...}
}
```

## Testing

Run the test suite:
```bash
php artisan test
```

## Deployment

1. **Production Environment**:
   ```bash
   APP_ENV=production
   APP_DEBUG=false
   ```

2. **Optimize for Production**:
   ```bash
   composer install --no-dev --optimize-autoloader
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```

3. **Set Up Queue Worker**:
   ```bash
   php artisan queue:work --daemon
   ```

## Support

For technical support or questions about the Taiga Ecommerce backend, please refer to the main project documentation or contact the development team.

## License

This project is part of the Taiga Ecommerce platform and follows the same licensing terms.