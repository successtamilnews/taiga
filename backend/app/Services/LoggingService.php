<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use Monolog\Handler\RotatingFileHandler;
use Monolog\Formatter\LineFormatter;
use Monolog\Formatter\JsonFormatter;

class LoggingService
{
    protected $loggers = [];
    protected $categories = [
        'security',
        'api',
        'orders',
        'payments',
        'delivery',
        'inventory',
        'users',
        'analytics',
        'websocket',
        'emergency',
        'performance',
        'errors',
        'audit',
        'notifications',
    ];

    public function __construct()
    {
        $this->initializeLoggers();
    }

    /**
     * Initialize specialized loggers for different categories
     */
    protected function initializeLoggers()
    {
        foreach ($this->categories as $category) {
            $logger = new Logger($category);
            
            // Add file handler
            $fileHandler = new RotatingFileHandler(
                storage_path("logs/{$category}.log"),
                7, // Keep 7 days
                Logger::DEBUG
            );
            $fileHandler->setFormatter(new JsonFormatter());
            $logger->pushHandler($fileHandler);
            
            // Add Redis handler for real-time monitoring (only if enabled)
            if (config('logging.real_time_enabled', false)) {
                $redisHandler = new class($category) extends \Monolog\Handler\AbstractProcessingHandler {
                protected $category;
                
                public function __construct($category) {
                    parent::__construct(Logger::DEBUG);
                    $this->category = $category;
                }
                
                protected function write(\Monolog\LogRecord $record): void {
                    try {
                        $logData = [
                            'category' => $this->category,
                            'level' => $record->level->name,
                            'message' => $record->message,
                            'context' => $record->context,
                            'extra' => $record->extra,
                            'timestamp' => $record->datetime->toISOString(),
                        ];
                        
                        // Store in Redis for real-time monitoring
                        Redis::zadd("logs:real_time:{$this->category}", 
                                  $record->datetime->getTimestamp(), 
                                  json_encode($logData));
                        Redis::expire("logs:real_time:{$this->category}", 86400); // 24 hours
                        
                        // Store critical logs separately
                        if ($record['level'] >= Logger::ERROR) {
                            Redis::zadd("logs:critical", 
                                      $record['datetime']->getTimestamp(), 
                                      json_encode($logData));
                            Redis::expire("logs:critical", 86400 * 7); // 7 days
                        }
                        
                        // Count logs by level
                        Redis::hincrby("logs:count:" . date('Y-m-d'), 
                                     $this->category . ':' . $record['level_name'], 1);
                        Redis::expire("logs:count:" . date('Y-m-d'), 86400 * 30); // 30 days
                        
                    } catch (\Exception $e) {
                        // Fallback logging to prevent infinite loops
                        error_log("Redis logging failed: " . $e->getMessage());
                    }
                }
            };
            $logger->pushHandler($redisHandler);
            }
            
            $this->loggers[$category] = $logger;
        }
    }

    /**
     * Log security events
     */
    public function logSecurity($event, $context = [])
    {
        $context = array_merge($context, [
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
            'user_id' => auth()->id(),
            'session_id' => session()->getId(),
        ]);

        $this->loggers['security']->info($event, $context);

        // Store security events in database for compliance
        $this->storeSecurityEvent($event, $context);
    }

    /**
     * Log API requests and responses
     */
    public function logApi($method, $endpoint, $responseTime, $statusCode, $context = [])
    {
        $level = $statusCode >= 400 ? 'error' : 'info';
        
        $context = array_merge($context, [
            'method' => $method,
            'endpoint' => $endpoint,
            'response_time' => $responseTime,
            'status_code' => $statusCode,
            'ip_address' => request()->ip(),
            'user_id' => auth()->id(),
        ]);

        $this->loggers['api']->log($level, "API {$method} {$endpoint} - {$statusCode}", $context);

        // Track API metrics in Redis
        $this->trackApiMetrics($method, $endpoint, $responseTime, $statusCode);
    }

    /**
     * Log order events
     */
    public function logOrder($event, $orderId, $context = [])
    {
        $context = array_merge($context, [
            'order_id' => $orderId,
            'user_id' => auth()->id(),
            'event_type' => $event,
        ]);

        $this->loggers['orders']->info("Order {$event}", $context);

        // Store order audit trail
        $this->storeOrderAudit($orderId, $event, $context);
    }

    /**
     * Log payment events
     */
    public function logPayment($event, $paymentId, $amount, $context = [])
    {
        $context = array_merge($context, [
            'payment_id' => $paymentId,
            'amount' => $amount,
            'currency' => $context['currency'] ?? 'USD',
            'payment_method' => $context['payment_method'] ?? 'unknown',
            'user_id' => auth()->id(),
        ]);

        $level = in_array($event, ['payment_failed', 'payment_disputed']) ? 'error' : 'info';
        $this->loggers['payments']->log($level, "Payment {$event}", $context);

        // Store payment audit for financial compliance
        $this->storePaymentAudit($paymentId, $event, $amount, $context);
    }

    /**
     * Log delivery events
     */
    public function logDelivery($event, $deliveryId, $context = [])
    {
        $context = array_merge($context, [
            'delivery_id' => $deliveryId,
            'delivery_person_id' => $context['delivery_person_id'] ?? null,
            'order_id' => $context['order_id'] ?? null,
            'location' => $context['location'] ?? null,
        ]);

        $level = in_array($event, ['delivery_failed', 'emergency_alert']) ? 'error' : 'info';
        $this->loggers['delivery']->log($level, "Delivery {$event}", $context);
    }

    /**
     * Log emergency events
     */
    public function logEmergency($event, $severity, $context = [])
    {
        $context = array_merge($context, [
            'severity' => $severity,
            'requires_immediate_action' => true,
            'alert_sent' => now()->toISOString(),
        ]);

        $this->loggers['emergency']->critical("Emergency: {$event}", $context);

        // Trigger immediate alerts
        $this->triggerEmergencyAlert($event, $severity, $context);
    }

    /**
     * Log inventory changes
     */
    public function logInventory($event, $productId, $oldValue, $newValue, $context = [])
    {
        $context = array_merge($context, [
            'product_id' => $productId,
            'old_value' => $oldValue,
            'new_value' => $newValue,
            'change_amount' => $newValue - $oldValue,
            'user_id' => auth()->id(),
        ]);

        $this->loggers['inventory']->info("Inventory {$event}", $context);
    }

    /**
     * Log user actions
     */
    public function logUser($event, $userId, $context = [])
    {
        $context = array_merge($context, [
            'target_user_id' => $userId,
            'action_by_user_id' => auth()->id(),
            'ip_address' => request()->ip(),
        ]);

        $level = in_array($event, ['account_locked', 'suspicious_activity']) ? 'warning' : 'info';
        $this->loggers['users']->log($level, "User {$event}", $context);
    }

    /**
     * Log analytics events
     */
    public function logAnalytics($event, $context = [])
    {
        $context = array_merge($context, [
            'user_id' => auth()->id(),
            'session_id' => session()->getId(),
        ]);

        $this->loggers['analytics']->debug("Analytics: {$event}", $context);
    }

    /**
     * Log WebSocket events
     */
    public function logWebSocket($event, $context = [])
    {
        $context = array_merge($context, [
            'server_instance' => gethostname(),
            'memory_usage' => memory_get_usage(true),
        ]);

        $level = in_array($event, ['connection_failed', 'message_failed']) ? 'error' : 'debug';
        $this->loggers['websocket']->log($level, "WebSocket: {$event}", $context);
    }

    /**
     * Log performance metrics
     */
    public function logPerformance($metric, $value, $context = [])
    {
        $context = array_merge($context, [
            'metric' => $metric,
            'value' => $value,
            'unit' => $context['unit'] ?? 'ms',
            'threshold' => $context['threshold'] ?? null,
            'server' => gethostname(),
        ]);

        $level = isset($context['threshold']) && $value > $context['threshold'] ? 'warning' : 'debug';
        $this->loggers['performance']->log($level, "Performance: {$metric}", $context);

        // Track performance metrics in Redis
        $this->trackPerformanceMetric($metric, $value, $context);
    }

    /**
     * Log application errors
     */
    public function logError($error, $context = [])
    {
        if ($error instanceof \Exception) {
            $context = array_merge($context, [
                'exception_class' => get_class($error),
                'file' => $error->getFile(),
                'line' => $error->getLine(),
                'trace' => $error->getTraceAsString(),
            ]);
            $message = $error->getMessage();
        } else {
            $message = (string) $error;
        }

        $this->loggers['errors']->error($message, $context);
    }

    /**
     * Log audit events for compliance
     */
    public function logAudit($action, $resource, $resourceId, $context = [])
    {
        $context = array_merge($context, [
            'action' => $action,
            'resource' => $resource,
            'resource_id' => $resourceId,
            'user_id' => auth()->id(),
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
        ]);

        $this->loggers['audit']->info("Audit: {$action} on {$resource}", $context);

        // Store audit trail in database
        $this->storeAuditTrail($action, $resource, $resourceId, $context);
    }

    /**
     * Log notification events
     */
    public function logNotification($event, $notificationId, $context = [])
    {
        $context = array_merge($context, [
            'notification_id' => $notificationId,
            'notification_type' => $context['type'] ?? 'unknown',
            'recipient_id' => $context['recipient_id'] ?? null,
            'channel' => $context['channel'] ?? 'unknown',
        ]);

        $level = in_array($event, ['notification_failed', 'delivery_failed']) ? 'error' : 'info';
        $this->loggers['notifications']->log($level, "Notification {$event}", $context);
    }

    /**
     * Get real-time logs for monitoring dashboard
     */
    public function getRealTimeLogs($category = null, $level = null, $limit = 100)
    {
        try {
            if ($category && in_array($category, $this->categories)) {
                $key = "logs:real_time:{$category}";
            } else {
                // Get logs from all categories
                $keys = array_map(function($cat) {
                    return "logs:real_time:{$cat}";
                }, $this->categories);
                
                // This would require a more complex Redis operation
                // For now, return logs from the errors category as default
                $key = "logs:real_time:errors";
            }

            $logs = Redis::zrevrange($key, 0, $limit - 1);
            
            $result = array_map(function($log) {
                return json_decode($log, true);
            }, $logs);

            // Filter by level if specified
            if ($level) {
                $result = array_filter($result, function($log) use ($level) {
                    return strtolower($log['level']) === strtolower($level);
                });
            }

            return $result;

        } catch (\Exception $e) {
            Log::error('Failed to get real-time logs: ' . $e->getMessage());
            return [];
        }
    }

    /**
     * Get log statistics
     */
    public function getLogStatistics($date = null)
    {
        try {
            $date = $date ?: date('Y-m-d');
            $stats = Redis::hgetall("logs:count:{$date}");
            
            $result = [
                'date' => $date,
                'total_logs' => 0,
                'by_category' => [],
                'by_level' => [],
            ];

            foreach ($stats as $key => $count) {
                $parts = explode(':', $key);
                $category = $parts[0];
                $level = $parts[1];

                $result['total_logs'] += $count;
                $result['by_category'][$category] = ($result['by_category'][$category] ?? 0) + $count;
                $result['by_level'][$level] = ($result['by_level'][$level] ?? 0) + $count;
            }

            return $result;

        } catch (\Exception $e) {
            Log::error('Failed to get log statistics: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Search logs by criteria
     */
    public function searchLogs($criteria)
    {
        try {
            $query = DB::table('audit_logs');

            if (isset($criteria['category'])) {
                $query->where('category', $criteria['category']);
            }

            if (isset($criteria['level'])) {
                $query->where('level', $criteria['level']);
            }

            if (isset($criteria['user_id'])) {
                $query->where('user_id', $criteria['user_id']);
            }

            if (isset($criteria['date_from'])) {
                $query->where('created_at', '>=', $criteria['date_from']);
            }

            if (isset($criteria['date_to'])) {
                $query->where('created_at', '<=', $criteria['date_to']);
            }

            if (isset($criteria['search_term'])) {
                $query->where(function($q) use ($criteria) {
                    $q->where('message', 'like', '%' . $criteria['search_term'] . '%')
                      ->orWhere('context', 'like', '%' . $criteria['search_term'] . '%');
                });
            }

            return $query->orderBy('created_at', 'desc')
                         ->limit($criteria['limit'] ?? 100)
                         ->get();

        } catch (\Exception $e) {
            Log::error('Failed to search logs: ' . $e->getMessage());
            return collect();
        }
    }

    /**
     * Export logs for compliance or analysis
     */
    public function exportLogs($criteria, $format = 'json')
    {
        try {
            $logs = $this->searchLogs($criteria);
            $filename = 'logs_export_' . date('Y-m-d_H-i-s') . '.' . $format;

            switch ($format) {
                case 'csv':
                    return $this->exportToCsv($logs, $filename);
                case 'json':
                default:
                    return $this->exportToJson($logs, $filename);
            }

        } catch (\Exception $e) {
            Log::error('Failed to export logs: ' . $e->getMessage());
            return null;
        }
    }

    // Helper methods

    protected function storeSecurityEvent($event, $context)
    {
        try {
            DB::table('security_logs')->insert([
                'event' => $event,
                'context' => json_encode($context),
                'ip_address' => $context['ip_address'] ?? null,
                'user_id' => $context['user_id'] ?? null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to store security event: ' . $e->getMessage());
        }
    }

    protected function storeOrderAudit($orderId, $event, $context)
    {
        try {
            DB::table('order_audit_logs')->insert([
                'order_id' => $orderId,
                'event' => $event,
                'context' => json_encode($context),
                'user_id' => $context['user_id'] ?? null,
                'created_at' => now(),
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to store order audit: ' . $e->getMessage());
        }
    }

    protected function storePaymentAudit($paymentId, $event, $amount, $context)
    {
        try {
            DB::table('payment_audit_logs')->insert([
                'payment_id' => $paymentId,
                'event' => $event,
                'amount' => $amount,
                'context' => json_encode($context),
                'user_id' => $context['user_id'] ?? null,
                'created_at' => now(),
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to store payment audit: ' . $e->getMessage());
        }
    }

    protected function storeAuditTrail($action, $resource, $resourceId, $context)
    {
        try {
            DB::table('audit_logs')->insert([
                'action' => $action,
                'resource' => $resource,
                'resource_id' => $resourceId,
                'context' => json_encode($context),
                'user_id' => $context['user_id'] ?? null,
                'ip_address' => $context['ip_address'] ?? null,
                'created_at' => now(),
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to store audit trail: ' . $e->getMessage());
        }
    }

    protected function trackApiMetrics($method, $endpoint, $responseTime, $statusCode)
    {
        try {
            $key = "api_metrics:" . date('Y-m-d:H');
            
            Redis::hincrby("{$key}:requests", "{$method}:{$endpoint}", 1);
            Redis::hincrby("{$key}:status_codes", $statusCode, 1);
            
            // Track response times (using sorted sets for percentile calculations)
            Redis::zadd("{$key}:response_times:{$method}:{$endpoint}", 
                      $responseTime, uniqid());
            
            // Set expiration
            Redis::expire("{$key}:requests", 86400 * 7);
            Redis::expire("{$key}:status_codes", 86400 * 7);
            Redis::expire("{$key}:response_times:{$method}:{$endpoint}", 86400 * 7);
            
        } catch (\Exception $e) {
            Log::error('Failed to track API metrics: ' . $e->getMessage());
        }
    }

    protected function trackPerformanceMetric($metric, $value, $context)
    {
        try {
            $key = "performance_metrics:" . date('Y-m-d:H');
            
            Redis::zadd("{$key}:{$metric}", $value, uniqid());
            Redis::expire("{$key}:{$metric}", 86400 * 7);
            
        } catch (\Exception $e) {
            Log::error('Failed to track performance metric: ' . $e->getMessage());
        }
    }

    protected function triggerEmergencyAlert($event, $severity, $context)
    {
        try {
            // Send to monitoring systems, Slack, email, etc.
            // This would integrate with your alert management system
            
        } catch (\Exception $e) {
            Log::error('Failed to trigger emergency alert: ' . $e->getMessage());
        }
    }

    protected function exportToJson($logs, $filename)
    {
        $data = json_encode($logs->toArray(), JSON_PRETTY_PRINT);
        Storage::put("exports/{$filename}", $data);
        
        return "exports/{$filename}";
    }

    protected function exportToCsv($logs, $filename)
    {
        $csv = "timestamp,category,level,message,context\n";
        
        foreach ($logs as $log) {
            $csv .= implode(',', [
                $log->created_at,
                $log->category ?? '',
                $log->level ?? '',
                '"' . str_replace('"', '""', $log->message) . '"',
                '"' . str_replace('"', '""', $log->context) . '"',
            ]) . "\n";
        }
        
        Storage::put("exports/{$filename}", $csv);
        
        return "exports/{$filename}";
    }
}