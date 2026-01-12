<?php

return [
    /*
    |--------------------------------------------------------------------------
    | WebSocket Configuration
    |--------------------------------------------------------------------------
    |
    | Configure WebSocket server settings for real-time communication
    | across customer, seller, and delivery applications.
    |
    */

    'enabled' => env('WEBSOCKET_ENABLED', true),
    
    'host' => env('WEBSOCKET_HOST', '0.0.0.0'),
    'port' => env('WEBSOCKET_PORT', 6001),
    
    'ssl' => [
        'enabled' => env('WEBSOCKET_SSL_ENABLED', false),
        'cert_path' => env('WEBSOCKET_SSL_CERT_PATH'),
        'key_path' => env('WEBSOCKET_SSL_KEY_PATH'),
        'passphrase' => env('WEBSOCKET_SSL_PASSPHRASE'),
    ],

    'auth' => [
        'jwt_secret' => env('JWT_SECRET'),
        'token_expiry' => 3600, // 1 hour in seconds
    ],

    'channels' => [
        'customer' => [
            'orders.{order_id}',
            'chat.customer.{customer_id}',
            'notifications.customer.{customer_id}',
            'delivery_tracking.{order_id}',
            'promotions.customer.{customer_id}',
        ],
        'seller' => [
            'orders.seller.{seller_id}',
            'inventory.seller.{seller_id}',
            'chat.seller.{seller_id}',
            'notifications.seller.{seller_id}',
            'analytics.seller.{seller_id}',
            'performance.seller.{seller_id}',
        ],
        'delivery' => [
            'deliveries.{delivery_person_id}',
            'routes.{delivery_person_id}',
            'location.{delivery_person_id}',
            'notifications.delivery.{delivery_person_id}',
            'emergency.{delivery_person_id}',
            'traffic.zone.{zone_id}',
        ],
        'admin' => [
            'system.admin',
            'analytics.admin',
            'monitoring.admin',
            'alerts.admin',
        ],
        'public' => [
            'system_announcements',
            'maintenance_mode',
            'traffic_alerts.public',
        ],
    ],

    'events' => [
        'connection' => [
            'user_connected',
            'user_disconnected',
            'heartbeat',
        ],
        'orders' => [
            'order_created',
            'order_updated',
            'order_accepted',
            'order_rejected',
            'order_preparing',
            'order_ready',
            'order_picked_up',
            'order_delivered',
            'order_cancelled',
            'payment_updated',
        ],
        'delivery' => [
            'delivery_assigned',
            'delivery_accepted',
            'delivery_rejected',
            'delivery_started',
            'location_updated',
            'delivery_completed',
            'delivery_issue_reported',
            'route_optimized',
            'emergency_alert',
        ],
        'inventory' => [
            'stock_updated',
            'low_stock_alert',
            'out_of_stock',
            'price_updated',
        ],
        'communication' => [
            'chat_message',
            'customer_query',
            'support_ticket',
        ],
        'analytics' => [
            'performance_metrics',
            'real_time_stats',
            'alert_threshold_reached',
        ],
    ],

    'rate_limiting' => [
        'enabled' => env('WEBSOCKET_RATE_LIMITING', true),
        'messages_per_minute' => 60,
        'connections_per_ip' => 10,
        'burst_limit' => 10,
    ],

    'heartbeat' => [
        'interval' => 30, // seconds
        'timeout' => 60, // seconds
        'max_missed' => 3,
    ],

    'message_queue' => [
        'enabled' => env('WEBSOCKET_QUEUE_ENABLED', true),
        'driver' => env('WEBSOCKET_QUEUE_DRIVER', 'redis'),
        'batch_size' => 100,
        'retry_attempts' => 3,
    ],

    'scaling' => [
        'clustering' => env('WEBSOCKET_CLUSTERING', false),
        'redis_cluster' => [
            'host' => env('REDIS_HOST', '127.0.0.1'),
            'port' => env('REDIS_PORT', 6379),
            'password' => env('REDIS_PASSWORD'),
            'database' => env('REDIS_WEBSOCKET_DB', 2),
        ],
        'load_balancer' => [
            'enabled' => env('WEBSOCKET_LOAD_BALANCER', false),
            'sticky_sessions' => true,
        ],
    ],

    'monitoring' => [
        'metrics_enabled' => env('WEBSOCKET_METRICS_ENABLED', true),
        'log_level' => env('WEBSOCKET_LOG_LEVEL', 'info'),
        'performance_tracking' => true,
        'connection_stats' => true,
        'message_stats' => true,
    ],

    'security' => [
        'cors' => [
            'enabled' => true,
            'allowed_origins' => explode(',', env('WEBSOCKET_CORS_ORIGINS', 'localhost,127.0.0.1')),
            'allowed_methods' => ['GET', 'POST'],
            'allowed_headers' => ['Authorization', 'Content-Type'],
        ],
        'csrf_protection' => env('WEBSOCKET_CSRF_PROTECTION', false),
        'ip_whitelist' => explode(',', env('WEBSOCKET_IP_WHITELIST', '')),
        'ddos_protection' => [
            'enabled' => env('WEBSOCKET_DDOS_PROTECTION', true),
            'max_connections_per_minute' => 100,
            'ban_duration' => 3600, // 1 hour
        ],
    ],

    'storage' => [
        'connection_store' => 'redis',
        'message_history' => [
            'enabled' => env('WEBSOCKET_MESSAGE_HISTORY', true),
            'retention_days' => 30,
            'max_messages_per_channel' => 1000,
        ],
        'presence' => [
            'enabled' => env('WEBSOCKET_PRESENCE', true),
            'timeout' => 300, // 5 minutes
        ],
    ],

    'hooks' => [
        'before_connect' => null,
        'after_connect' => null,
        'before_disconnect' => null,
        'after_disconnect' => null,
        'before_message' => null,
        'after_message' => null,
    ],

    'debugging' => [
        'enabled' => env('WEBSOCKET_DEBUG', false),
        'verbose_logging' => env('WEBSOCKET_VERBOSE_LOGGING', false),
        'performance_profiling' => env('WEBSOCKET_PROFILING', false),
    ],
];