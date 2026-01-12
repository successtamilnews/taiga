<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Analytics Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for the enhanced analytics system including real-time
    | tracking, performance monitoring, and business intelligence.
    |
    */

    'enabled' => env('ANALYTICS_ENABLED', true),

    /*
    |--------------------------------------------------------------------------
    | Real-time Analytics
    |--------------------------------------------------------------------------
    */
    'real_time' => [
        'enabled' => env('ANALYTICS_REAL_TIME_ENABLED', true),
        'batch_size' => env('ANALYTICS_BATCH_SIZE', 100),
        'flush_interval' => env('ANALYTICS_FLUSH_INTERVAL', 60), // seconds
        'redis_connection' => env('REDIS_ANALYTICS_DB', 4),
    ],

    /*
    |--------------------------------------------------------------------------
    | Data Retention
    |--------------------------------------------------------------------------
    */
    'retention' => [
        'days' => env('ANALYTICS_RETENTION_DAYS', 90),
        'real_time_hours' => 24,
        'aggregated_months' => 12,
    ],

    /*
    |--------------------------------------------------------------------------
    | Event Types
    |--------------------------------------------------------------------------
    */
    'event_types' => [
        'page_view',
        'api_request',
        'user_action',
        'order_placed',
        'payment_processed',
        'product_viewed',
        'product_added_to_cart',
        'search_performed',
        'user_registered',
        'user_login',
        'inventory_updated',
        'delivery_status_changed',
        'chat_message_sent',
        'emergency_alert_triggered',
    ],

    /*
    |--------------------------------------------------------------------------
    | User Types
    |--------------------------------------------------------------------------
    */
    'user_types' => [
        'anonymous',
        'customer',
        'seller',
        'delivery',
        'admin',
    ],

    /*
    |--------------------------------------------------------------------------
    | Performance Tracking
    |--------------------------------------------------------------------------
    */
    'performance' => [
        'enabled' => env('ANALYTICS_PERFORMANCE_ENABLED', true),
        'slow_query_threshold' => env('PERFORMANCE_SLOW_QUERY_THRESHOLD', 1000), // milliseconds
        'memory_threshold' => env('PERFORMANCE_MEMORY_THRESHOLD', 128), // MB
        'cpu_threshold' => env('PERFORMANCE_CPU_THRESHOLD', 80), // percentage
    ],

    /*
    |--------------------------------------------------------------------------
    | Business Intelligence
    |--------------------------------------------------------------------------
    */
    'business_intelligence' => [
        'enabled' => true,
        'conversion_tracking' => true,
        'revenue_analytics' => true,
        'user_segmentation' => true,
        'predictive_analytics' => false, // Requires additional ML libraries
    ],

    /*
    |--------------------------------------------------------------------------
    | Reporting
    |--------------------------------------------------------------------------
    */
    'reporting' => [
        'enabled' => true,
        'auto_generation' => [
            'daily' => true,
            'weekly' => true,
            'monthly' => true,
        ],
        'formats' => ['json', 'csv'],
        'storage_path' => storage_path('app/reports/analytics'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Privacy & Compliance
    |--------------------------------------------------------------------------
    */
    'privacy' => [
        'anonymize_ip' => true,
        'respect_dnt' => true, // Do Not Track header
        'gdpr_compliance' => true,
        'data_retention_policy' => true,
    ],

];