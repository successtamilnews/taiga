<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Performance Monitoring Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for comprehensive performance monitoring including
    | real-time metrics, alerting, and optimization recommendations.
    |
    */

    'enabled' => env('PERFORMANCE_MONITORING_ENABLED', true),

    /*
    |--------------------------------------------------------------------------
    | Monitoring Thresholds
    |--------------------------------------------------------------------------
    */
    'thresholds' => [
        'response_time' => [
            'warning' => 500, // milliseconds
            'critical' => 1000, // milliseconds
        ],
        'memory_usage' => [
            'warning' => env('PERFORMANCE_MEMORY_THRESHOLD', 128), // MB
            'critical' => 256, // MB
        ],
        'cpu_usage' => [
            'warning' => env('PERFORMANCE_CPU_THRESHOLD', 70), // percentage
            'critical' => 90, // percentage
        ],
        'database_queries' => [
            'warning' => 50, // queries per request
            'critical' => 100, // queries per request
        ],
        'database_query_time' => [
            'warning' => 100, // milliseconds
            'critical' => 500, // milliseconds
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Metrics Collection
    |--------------------------------------------------------------------------
    */
    'metrics' => [
        'response_time' => true,
        'memory_usage' => true,
        'cpu_usage' => false, // Requires system monitoring extension
        'database_performance' => true,
        'cache_performance' => true,
        'queue_performance' => true,
        'websocket_connections' => true,
        'api_endpoints' => true,
    ],

    /*
    |--------------------------------------------------------------------------
    | Real-time Monitoring
    |--------------------------------------------------------------------------
    */
    'real_time' => [
        'enabled' => true,
        'sample_rate' => 1.0, // 100% sampling in development, reduce in production
        'buffer_size' => 1000,
        'flush_interval' => 30, // seconds
        'redis_connection' => 'default',
    ],

    /*
    |--------------------------------------------------------------------------
    | Alerting
    |--------------------------------------------------------------------------
    */
    'alerting' => [
        'enabled' => true,
        'channels' => [
            'log' => true,
            'email' => false, // Configure MAIL_* settings
            'slack' => false, // Configure Slack webhook
            'discord' => false, // Configure Discord webhook
        ],
        'throttle' => [
            'same_alert' => 300, // seconds (5 minutes)
            'max_alerts_per_hour' => 10,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Profiling
    |--------------------------------------------------------------------------
    */
    'profiling' => [
        'enabled' => env('APP_DEBUG', false),
        'slow_requests' => [
            'enabled' => true,
            'threshold' => 1000, // milliseconds
            'detailed_trace' => true,
        ],
        'memory_intensive' => [
            'enabled' => true,
            'threshold' => 64, // MB
        ],
        'database_heavy' => [
            'enabled' => true,
            'query_threshold' => 20,
            'time_threshold' => 100, // milliseconds
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Data Retention
    |--------------------------------------------------------------------------
    */
    'retention' => [
        'real_time_hours' => 24,
        'hourly_days' => 7,
        'daily_months' => 3,
        'monthly_years' => 1,
    ],

    /*
    |--------------------------------------------------------------------------
    | Optimization Recommendations
    |--------------------------------------------------------------------------
    */
    'optimization' => [
        'enabled' => true,
        'automatic_suggestions' => [
            'cache_optimization' => true,
            'query_optimization' => true,
            'code_optimization' => false, // Requires static analysis
        ],
        'reports' => [
            'daily' => false,
            'weekly' => true,
            'monthly' => true,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Monitoring Endpoints
    |--------------------------------------------------------------------------
    */
    'endpoints' => [
        'exclude_patterns' => [
            '/health',
            '/up',
            '/metrics',
            '/favicon.ico',
        ],
        'include_only' => [], // If not empty, only these patterns will be monitored
        'api_monitoring' => [
            'enabled' => true,
            'detailed_logging' => true,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | WebSocket Monitoring
    |--------------------------------------------------------------------------
    */
    'websocket' => [
        'connection_monitoring' => true,
        'message_monitoring' => true,
        'performance_tracking' => true,
        'error_tracking' => true,
    ],

    /*
    |--------------------------------------------------------------------------
    | External Integrations
    |--------------------------------------------------------------------------
    */
    'integrations' => [
        'new_relic' => [
            'enabled' => false,
            'api_key' => env('NEW_RELIC_API_KEY'),
        ],
        'datadog' => [
            'enabled' => false,
            'api_key' => env('DATADOG_API_KEY'),
        ],
        'prometheus' => [
            'enabled' => false,
            'endpoint' => '/metrics',
        ],
    ],

];