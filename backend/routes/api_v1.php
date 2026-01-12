<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ProductController;
use App\Http\Controllers\Api\V1\CategoryController;
use App\Http\Controllers\Api\V1\OrderController;
use App\Http\Controllers\Api\V1\WishlistController;
use App\Http\Controllers\Api\V1\ShippingAddressController;
use App\Http\Controllers\Api\VendorController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AnalyticsController;
use App\Http\Controllers\Api\WebSocketController;
use App\Http\Controllers\Api\LoggingController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public routes
Route::prefix('v1')->group(function () {
    // Authentication routes
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    
    // Public product routes
    Route::get('/products', [ProductController::class, 'index']);
    Route::get('/products/featured', [ProductController::class, 'featured']);
    Route::get('/products/{id}', [ProductController::class, 'show']);
    Route::get('/products/{id}/related', [ProductController::class, 'related']);
    Route::get('/products/{id}/reviews', [ProductController::class, 'reviews']);
    
    // Public category routes
    Route::get('/categories', [CategoryController::class, 'index']);
    Route::get('/categories/{id}', [CategoryController::class, 'show']);
    Route::get('/categories/{id}/products', [CategoryController::class, 'products']);
});

// Protected routes
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    // Authentication routes
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::put('/profile', [AuthController::class, 'updateProfile']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);
    
    // Order routes
    Route::get('/orders', [OrderController::class, 'index']);
    Route::post('/orders', [OrderController::class, 'store']);
    Route::get('/orders/{id}', [OrderController::class, 'show']);
    Route::post('/orders/{id}/cancel', [OrderController::class, 'cancel']);
    
    // Wishlist routes
    Route::get('/wishlist', [WishlistController::class, 'index']);
    Route::post('/wishlist', [WishlistController::class, 'store']);
    Route::delete('/wishlist/{productId}', [WishlistController::class, 'destroy']);
    Route::get('/wishlist/check/{productId}', [WishlistController::class, 'check']);
    Route::delete('/wishlist', [WishlistController::class, 'clear']);
    
    // Shipping addresses routes
    Route::get('/shipping-addresses', [ShippingAddressController::class, 'index']);
    Route::post('/shipping-addresses', [ShippingAddressController::class, 'store']);
    Route::put('/shipping-addresses/{id}', [ShippingAddressController::class, 'update']);
    Route::delete('/shipping-addresses/{id}', [ShippingAddressController::class, 'destroy']);
    Route::post('/shipping-addresses/{id}/set-default', [ShippingAddressController::class, 'setDefault']);
});

// Legacy route for backward compatibility
Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Authentication Routes
Route::prefix('auth')->middleware('api')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');
    Route::post('refresh', [AuthController::class, 'refresh'])->middleware('auth:sanctum');
    Route::get('profile', [AuthController::class, 'profile'])->middleware('auth:sanctum');
});

// Vendor Routes
Route::prefix('vendor')->middleware(['auth:sanctum', 'role:vendor'])->group(function () {
    Route::get('dashboard', [VendorController::class, 'dashboard']);
    Route::get('statistics', [VendorController::class, 'getStatistics']);
    
    Route::prefix('products')->group(function () {
        Route::get('/', [VendorController::class, 'getProducts']);
        Route::post('/', [VendorController::class, 'createProduct']);
        Route::get('{id}', [VendorController::class, 'getProduct']);
        Route::put('{id}', [VendorController::class, 'updateProduct']);
        Route::delete('{id}', [VendorController::class, 'deleteProduct']);
        Route::post('{id}/images', [VendorController::class, 'uploadProductImages']);
        Route::delete('{id}/images/{imageId}', [VendorController::class, 'deleteProductImage']);
    });
    
    Route::prefix('orders')->group(function () {
        Route::get('/', [VendorController::class, 'getOrders']);
        Route::get('{id}', [VendorController::class, 'getOrder']);
        Route::put('{id}/status', [VendorController::class, 'updateOrderStatus']);
        Route::post('{id}/assign-delivery', [VendorController::class, 'assignDelivery']);
    });
    
    Route::prefix('payments')->group(function () {
        Route::get('/', [VendorController::class, 'getPayments']);
        Route::post('withdraw', [VendorController::class, 'requestWithdrawal']);
    });
});

// Admin Routes
Route::prefix('admin')->middleware(['auth:sanctum', 'role:admin'])->group(function () {
    Route::get('dashboard', [AdminController::class, 'dashboard']);
    Route::get('statistics', [AdminController::class, 'getStatistics']);
    
    Route::prefix('users')->group(function () {
        Route::get('/', [AdminController::class, 'getUsers']);
        Route::get('{id}', [AdminController::class, 'getUser']);
        Route::put('{id}', [AdminController::class, 'updateUser']);
        Route::delete('{id}', [AdminController::class, 'deleteUser']);
        Route::post('{id}/ban', [AdminController::class, 'banUser']);
        Route::post('{id}/unban', [AdminController::class, 'unbanUser']);
    });
    
    Route::prefix('vendors')->group(function () {
        Route::get('/', [AdminController::class, 'getVendors']);
        Route::get('{id}', [AdminController::class, 'getVendor']);
        Route::put('{id}/approve', [AdminController::class, 'approveVendor']);
        Route::put('{id}/reject', [AdminController::class, 'rejectVendor']);
        Route::put('{id}/suspend', [AdminController::class, 'suspendVendor']);
    });
    
    Route::prefix('products')->group(function () {
        Route::get('/', [AdminController::class, 'getAllProducts']);
        Route::get('{id}', [AdminController::class, 'getProduct']);
        Route::put('{id}/approve', [AdminController::class, 'approveProduct']);
        Route::put('{id}/reject', [AdminController::class, 'rejectProduct']);
        Route::delete('{id}', [AdminController::class, 'deleteProduct']);
    });

    // Category Management
    Route::prefix('categories')->group(function () {
        Route::get('/', [AdminController::class, 'getCategories']);
        Route::post('/', [AdminController::class, 'createCategory']);
        Route::put('{id}', [AdminController::class, 'updateCategory']);
        Route::delete('{id}', [AdminController::class, 'deleteCategory']);
    });
    
    Route::prefix('orders')->group(function () {
        Route::get('/', [AdminController::class, 'getAllOrders']);
        Route::get('{id}', [AdminController::class, 'getOrder']);
        Route::put('{id}/status', [AdminController::class, 'updateOrderStatus']);
    });
    
    Route::prefix('analytics')->group(function () {
        Route::get('sales', [AnalyticsController::class, 'getSalesAnalytics']);
        Route::get('revenue', [AnalyticsController::class, 'getRevenueAnalytics']);
        Route::get('users', [AnalyticsController::class, 'getUserAnalytics']);
        Route::get('products', [AnalyticsController::class, 'getProductAnalytics']);
        Route::get('vendors', [AnalyticsController::class, 'getVendorAnalytics']);
        Route::post('export', [AnalyticsController::class, 'exportReport']);
    });
    
    Route::prefix('logging')->group(function () {
        Route::post('events', [LoggingController::class, 'logEvent']);
        Route::get('real-time', [LoggingController::class, 'getRealTimeLogs']);
        Route::get('statistics', [LoggingController::class, 'getLogStatistics']);
        Route::get('search', [LoggingController::class, 'searchLogs']);
        Route::post('export', [LoggingController::class, 'exportLogs']);
        Route::get('download/{filename}', [LoggingController::class, 'downloadExport']);
        Route::get('categories', [LoggingController::class, 'getLogCategories']);
    });
});

// Webhook Routes (for payment gateways)
Route::prefix('webhooks')->group(function () {
    Route::post('google-pay', [PaymentController::class, 'googlePayWebhook']);
    Route::post('apple-pay', [PaymentController::class, 'applePayWebhook']);
    Route::post('sampath-bank', [PaymentController::class, 'sampathBankWebhook']);
});