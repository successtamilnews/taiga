<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Services\AnalyticsService;
use App\Services\BroadcastService;
use App\Services\LoggingService;
use App\Services\WebSocketService;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Register Analytics Service as Singleton
        $this->app->singleton(AnalyticsService::class, function ($app) {
            return new AnalyticsService();
        });

        // Register Broadcast Service as Singleton
        $this->app->singleton(BroadcastService::class, function ($app) {
            return new BroadcastService();
        });

        // Register Logging Service as Singleton
        $this->app->singleton(LoggingService::class, function ($app) {
            return new LoggingService();
        });

        // Register WebSocket Service as Singleton
        $this->app->singleton(WebSocketService::class, function ($app) {
            return new WebSocketService();
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Register console commands
        if ($this->app->runningInConsole()) {
            $this->commands([
                \App\Console\Commands\WebSocketServerCommand::class,
            ]);
        }

        // Set up event listeners for real-time broadcasting
        $this->setupEventListeners();
    }

    /**
     * Set up event listeners for automatic broadcasting
     */
    protected function setupEventListeners(): void
    {
        // Order events
        \App\Models\Order::created(function ($order) {
            $broadcastService = app(BroadcastService::class);
            $broadcastService->broadcastNewOrder($order);
        });

        \App\Models\Order::updated(function ($order) {
            if ($order->wasChanged('status')) {
                $broadcastService = app(BroadcastService::class);
                $broadcastService->broadcastOrderUpdate(
                    $order, 
                    $order->status, 
                    ['previous_status' => $order->getOriginal('status')]
                );
            }
        });

        // Product events (inventory updates)
        \App\Models\Product::updated(function ($product) {
            if ($product->wasChanged('stock_quantity')) {
                $broadcastService = app(BroadcastService::class);
                $broadcastService->broadcastInventoryUpdate(
                    $product,
                    $product->getOriginal('stock_quantity'),
                    $product->stock_quantity
                );
            }
        });

        // Payment events
        \App\Models\Payment::created(function ($payment) {
            $loggingService = app(LoggingService::class);
            $loggingService->logPayment(
                'payment_created',
                $payment->id,
                $payment->amount,
                [
                    'payment_method' => $payment->payment_method,
                    'currency' => $payment->currency,
                    'order_id' => $payment->order_id,
                ]
            );
        });

        \App\Models\Payment::updated(function ($payment) {
            if ($payment->wasChanged('status')) {
                $loggingService = app(LoggingService::class);
                $loggingService->logPayment(
                    "payment_{$payment->status}",
                    $payment->id,
                    $payment->amount,
                    [
                        'previous_status' => $payment->getOriginal('status'),
                        'payment_method' => $payment->payment_method,
                        'currency' => $payment->currency,
                    ]
                );
            }
        });

        // User events
        \App\Models\User::created(function ($user) {
            $analyticsService = app(AnalyticsService::class);
            $analyticsService->recordEvent(
                $user->id,
                'user_registered',
                [
                    'user_type' => $user->user_type,
                    'registration_method' => 'standard',
                ],
                $user->user_type
            );
        });

        \App\Models\User::updated(function ($user) {
            if ($user->wasChanged('is_active')) {
                $loggingService = app(LoggingService::class);
                $loggingService->logUser(
                    $user->is_active ? 'account_activated' : 'account_deactivated',
                    $user->id,
                    [
                        'previous_status' => $user->getOriginal('is_active'),
                        'user_type' => $user->user_type,
                    ]
                );
            }
        });
    }
}
