<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\VendorController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\OrderController;
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

// Load additional API v1 routes
require __DIR__.'/api_v1.php';

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Authentication Routes
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('reset-password', [AuthController::class, 'resetPassword']);
    
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::get('profile', [AuthController::class, 'profile']);
        Route::put('profile', [AuthController::class, 'updateProfile']);
    });
});

// Health check (for container/ingress health)
Route::get('health', function () {
    return response()->json(['status' => 'ok']);
});

// Public Routes
Route::get('products', [ProductController::class, 'index']);
Route::get('products/{product}', [ProductController::class, 'show']);
Route::get('categories', [ProductController::class, 'categories']);
Route::get('vendors', [VendorController::class, 'publicIndex']);

// Protected Routes
Route::middleware('auth:sanctum')->group(function () {
    
    // User Routes
    Route::prefix('user')->group(function () {
        Route::get('orders', [OrderController::class, 'userOrders']);
        Route::post('orders', [OrderController::class, 'store']);
        Route::get('orders/{order}', [OrderController::class, 'show']);
        Route::put('orders/{order}/cancel', [OrderController::class, 'cancel']);
    });
    
    // Vendor Routes
    Route::middleware('role:vendor')->prefix('vendor')->group(function () {
        Route::get('dashboard', [VendorController::class, 'dashboard']);
        Route::apiResource('products', ProductController::class);
        Route::get('orders', [OrderController::class, 'vendorOrders']);
        Route::put('orders/{order}/status', [OrderController::class, 'updateStatus']);
        Route::get('analytics', [VendorController::class, 'analytics']);
        Route::get('commission', [VendorController::class, 'commission']);
    });
    
    // Delivery Routes
    Route::middleware('role:delivery')->prefix('delivery')->group(function () {
        Route::get('orders', [OrderController::class, 'deliveryOrders']);
        Route::put('orders/{order}/pickup', [OrderController::class, 'markPickedUp']);
        Route::put('orders/{order}/deliver', [OrderController::class, 'markDelivered']);
        Route::post('orders/{order}/location', [OrderController::class, 'updateLocation']);
    });
    
    // Payment Routes
    Route::prefix('payments')->group(function () {
        Route::post('process', [PaymentController::class, 'process']);
        Route::post('google-pay', [PaymentController::class, 'googlePay']);
        Route::post('apple-pay', [PaymentController::class, 'applePay']);
        Route::post('sampath-bank', [PaymentController::class, 'sampathBank']);
        Route::get('history', [PaymentController::class, 'history']);
    });
    
    // Admin Routes
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('dashboard', [AdminController::class, 'dashboard']);
        Route::get('analytics', [AdminController::class, 'analytics']);
        
        // User Management
        Route::get('users', [AdminController::class, 'users']);
        Route::put('users/{user}/status', [AdminController::class, 'updateUserStatus']);
        
        // Vendor Management
        Route::get('vendors', [AdminController::class, 'vendors']);
        Route::put('vendors/{vendor}/approve', [AdminController::class, 'approveVendor']);
        Route::put('vendors/{vendor}/commission', [AdminController::class, 'updateCommission']);
        
        // Order Management
        Route::get('orders', [AdminController::class, 'orders']);
        Route::get('orders/stats', [AdminController::class, 'orderStats']);
        
        // Product Management
        Route::get('products', [AdminController::class, 'products']);
        Route::put('products/{product}/approve', [AdminController::class, 'approveProduct']);
        
        // Reports
        Route::get('reports/sales', [AdminController::class, 'salesReport']);
        Route::get('reports/vendors', [AdminController::class, 'vendorReport']);
        Route::get('reports/customers', [AdminController::class, 'customerReport']);
        
        // Settings
        Route::get('settings', [AdminController::class, 'getSettings']);
        Route::put('settings', [AdminController::class, 'updateSettings']);
    });

    // Analytics Routes
    Route::prefix('analytics')->group(function () {
        Route::post('events', [AnalyticsController::class, 'recordEvent']);
        Route::get('real-time', [AnalyticsController::class, 'getRealTimeAnalytics']);
        Route::get('seller/{sellerId?}', [AnalyticsController::class, 'getSellerAnalytics']);
        Route::get('customer/{customerId?}', [AnalyticsController::class, 'getCustomerAnalytics']);
        Route::get('delivery/{deliveryPersonId?}', [AnalyticsController::class, 'getDeliveryAnalytics']);
        Route::get('platform', [AnalyticsController::class, 'getPlatformAnalytics']);
        Route::post('reports', [AnalyticsController::class, 'generateReport']);
        Route::delete('cache', [AnalyticsController::class, 'clearCache']);
    });

    // WebSocket Routes
    Route::prefix('websocket')->group(function () {
        Route::post('broadcast', [WebSocketController::class, 'broadcast']);
        Route::post('order-update', [WebSocketController::class, 'broadcastOrderUpdate']);
        Route::post('delivery-tracking', [WebSocketController::class, 'broadcastDeliveryTracking']);
        Route::post('emergency-alert', [WebSocketController::class, 'broadcastEmergencyAlert']);
        Route::post('chat', [WebSocketController::class, 'sendChatMessage']);
        Route::get('status', [WebSocketController::class, 'getUserStatus']);
        Route::get('server/stats', [WebSocketController::class, 'getServerStatistics']);
        Route::get('server/health', [WebSocketController::class, 'checkServerHealth']);
    });

    // Logging Routes
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