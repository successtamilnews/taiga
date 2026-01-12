<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\LoggingService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class LoggingController extends Controller
{
    protected $loggingService;

    public function __construct(LoggingService $loggingService)
    {
        $this->loggingService = $loggingService;
    }

    /**
     * Log a custom event
     */
    public function logEvent(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'category' => 'required|string|in:security,api,orders,payments,delivery,inventory,users,analytics,websocket,emergency,performance,errors,audit,notifications',
                'level' => 'required|string|in:debug,info,warning,error,critical',
                'message' => 'required|string',
                'context' => 'nullable|array',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $category = $request->input('category');
            $level = $request->input('level');
            $message = $request->input('message');
            $context = $request->input('context', []);

            // Add request context
            $context = array_merge($context, [
                'logged_by' => auth()->id(),
                'ip_address' => request()->ip(),
                'user_agent' => request()->userAgent(),
            ]);

            // Log based on category
            switch ($category) {
                case 'security':
                    $this->loggingService->logSecurity($message, $context);
                    break;
                case 'api':
                    $this->loggingService->logApi(
                        $context['method'] ?? 'UNKNOWN',
                        $context['endpoint'] ?? '',
                        $context['response_time'] ?? 0,
                        $context['status_code'] ?? 200,
                        $context
                    );
                    break;
                case 'orders':
                    $this->loggingService->logOrder(
                        $message,
                        $context['order_id'] ?? 0,
                        $context
                    );
                    break;
                case 'payments':
                    $this->loggingService->logPayment(
                        $message,
                        $context['payment_id'] ?? 0,
                        $context['amount'] ?? 0,
                        $context
                    );
                    break;
                case 'delivery':
                    $this->loggingService->logDelivery(
                        $message,
                        $context['delivery_id'] ?? 0,
                        $context
                    );
                    break;
                case 'emergency':
                    $this->loggingService->logEmergency(
                        $message,
                        $context['severity'] ?? 'medium',
                        $context
                    );
                    break;
                case 'inventory':
                    $this->loggingService->logInventory(
                        $message,
                        $context['product_id'] ?? 0,
                        $context['old_value'] ?? 0,
                        $context['new_value'] ?? 0,
                        $context
                    );
                    break;
                case 'users':
                    $this->loggingService->logUser(
                        $message,
                        $context['user_id'] ?? 0,
                        $context
                    );
                    break;
                case 'analytics':
                    $this->loggingService->logAnalytics($message, $context);
                    break;
                case 'websocket':
                    $this->loggingService->logWebSocket($message, $context);
                    break;
                case 'performance':
                    $this->loggingService->logPerformance(
                        $context['metric'] ?? 'unknown',
                        $context['value'] ?? 0,
                        $context
                    );
                    break;
                case 'errors':
                    $this->loggingService->logError($message, $context);
                    break;
                case 'audit':
                    $this->loggingService->logAudit(
                        $context['action'] ?? 'unknown',
                        $context['resource'] ?? 'unknown',
                        $context['resource_id'] ?? 0,
                        $context
                    );
                    break;
                case 'notifications':
                    $this->loggingService->logNotification(
                        $message,
                        $context['notification_id'] ?? 0,
                        $context
                    );
                    break;
                default:
                    return response()->json([
                        'success' => false,
                        'message' => 'Unknown category',
                    ], 400);
            }

            return response()->json([
                'success' => true,
                'message' => 'Event logged successfully',
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to log event',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get real-time logs for monitoring
     */
    public function getRealTimeLogs(Request $request): JsonResponse
    {
        try {
            // Admin only
            if (auth()->user()->user_type !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin access required',
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'category' => 'nullable|string|in:security,api,orders,payments,delivery,inventory,users,analytics,websocket,emergency,performance,errors,audit,notifications',
                'level' => 'nullable|string|in:debug,info,warning,error,critical',
                'limit' => 'nullable|integer|min:1|max:1000',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $category = $request->input('category');
            $level = $request->input('level');
            $limit = $request->input('limit', 100);

            $logs = $this->loggingService->getRealTimeLogs($category, $level, $limit);

            return response()->json([
                'success' => true,
                'data' => $logs,
                'total' => count($logs),
            ]);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Real-time logs retrieval',
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Get log statistics
     */
    public function getLogStatistics(Request $request): JsonResponse
    {
        try {
            // Admin only
            if (auth()->user()->user_type !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin access required',
                ], 403);
            }

            $date = $request->input('date', date('Y-m-d'));
            
            // Validate date format
            if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid date format. Use YYYY-MM-DD',
                ], 400);
            }

            $statistics = $this->loggingService->getLogStatistics($date);

            if ($statistics) {
                return response()->json([
                    'success' => true,
                    'data' => $statistics,
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to get log statistics',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Log statistics retrieval',
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Search logs
     */
    public function searchLogs(Request $request): JsonResponse
    {
        try {
            // Admin only
            if (auth()->user()->user_type !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin access required',
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'category' => 'nullable|string',
                'level' => 'nullable|string',
                'user_id' => 'nullable|integer',
                'date_from' => 'nullable|date',
                'date_to' => 'nullable|date',
                'search_term' => 'nullable|string|max:255',
                'limit' => 'nullable|integer|min:1|max:1000',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $criteria = [
                'category' => $request->input('category'),
                'level' => $request->input('level'),
                'user_id' => $request->input('user_id'),
                'date_from' => $request->input('date_from'),
                'date_to' => $request->input('date_to'),
                'search_term' => $request->input('search_term'),
                'limit' => $request->input('limit', 100),
            ];

            // Remove null values
            $criteria = array_filter($criteria, function($value) {
                return $value !== null;
            });

            $logs = $this->loggingService->searchLogs($criteria);

            $this->loggingService->logAudit(
                'logs_searched',
                'logs',
                0,
                [
                    'search_criteria' => $criteria,
                    'results_count' => $logs->count(),
                ]
            );

            return response()->json([
                'success' => true,
                'data' => $logs,
                'total' => $logs->count(),
                'criteria' => $criteria,
            ]);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Log search',
                'request_data' => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Export logs
     */
    public function exportLogs(Request $request): JsonResponse
    {
        try {
            // Admin only
            if (auth()->user()->user_type !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin access required',
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'category' => 'nullable|string',
                'level' => 'nullable|string',
                'user_id' => 'nullable|integer',
                'date_from' => 'nullable|date',
                'date_to' => 'nullable|date',
                'search_term' => 'nullable|string|max:255',
                'format' => 'nullable|string|in:json,csv',
                'limit' => 'nullable|integer|min:1|max:10000',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $criteria = [
                'category' => $request->input('category'),
                'level' => $request->input('level'),
                'user_id' => $request->input('user_id'),
                'date_from' => $request->input('date_from'),
                'date_to' => $request->input('date_to'),
                'search_term' => $request->input('search_term'),
                'limit' => $request->input('limit', 1000),
            ];

            $format = $request->input('format', 'json');

            // Remove null values
            $criteria = array_filter($criteria, function($value) {
                return $value !== null;
            });

            $exportPath = $this->loggingService->exportLogs($criteria, $format);

            if ($exportPath) {
                $this->loggingService->logAudit(
                    'logs_exported',
                    'logs',
                    0,
                    [
                        'export_criteria' => $criteria,
                        'export_format' => $format,
                        'export_path' => $exportPath,
                    ]
                );

                return response()->json([
                    'success' => true,
                    'message' => 'Logs exported successfully',
                    'data' => [
                        'export_path' => $exportPath,
                        'format' => $format,
                        'download_url' => url("api/logging/download/{$exportPath}"),
                    ],
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to export logs',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Log export',
                'request_data' => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Download exported logs
     */
    public function downloadExport($filename): JsonResponse
    {
        try {
            // Admin only
            if (auth()->user()->user_type !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin access required',
                ], 403);
            }

            $filePath = storage_path("app/{$filename}");
            
            if (!file_exists($filePath)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Export file not found',
                ], 404);
            }

            $this->loggingService->logAudit(
                'export_downloaded',
                'logs',
                0,
                [
                    'filename' => $filename,
                ]
            );

            return response()->download($filePath)->deleteFileAfterSend(true);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Export download',
                'filename' => $filename,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Get log categories and their descriptions
     */
    public function getLogCategories(): JsonResponse
    {
        try {
            $categories = [
                'security' => 'Security-related events (authentication, authorization, suspicious activities)',
                'api' => 'API requests and responses',
                'orders' => 'Order lifecycle events (created, updated, cancelled, completed)',
                'payments' => 'Payment processing events (successful, failed, disputed)',
                'delivery' => 'Delivery and logistics events (assigned, picked up, delivered, failed)',
                'inventory' => 'Inventory management events (stock updates, low stock alerts)',
                'users' => 'User management events (registration, profile updates, account status)',
                'analytics' => 'Analytics and tracking events',
                'websocket' => 'Real-time communication events',
                'emergency' => 'Emergency and critical alerts',
                'performance' => 'Performance metrics and monitoring',
                'errors' => 'Application errors and exceptions',
                'audit' => 'Audit trail for compliance and governance',
                'notifications' => 'Notification system events (sent, failed, delivered)',
            ];

            return response()->json([
                'success' => true,
                'data' => $categories,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }
}