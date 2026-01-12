<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\AnalyticsService;
use App\Services\BroadcastService;
use App\Services\LoggingService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class AnalyticsController extends Controller
{
    protected $analyticsService;
    protected $loggingService;

    public function __construct(AnalyticsService $analyticsService, LoggingService $loggingService)
    {
        $this->analyticsService = $analyticsService;
        $this->loggingService = $loggingService;
    }

    /**
     * Record an analytics event
     */
    public function recordEvent(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'event_type' => 'required|string|max:100',
                'user_id' => 'nullable|integer|exists:users,id',
                'user_type' => 'nullable|string|in:customer,seller,delivery,admin',
                'event_data' => 'nullable|array',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $userId = $request->input('user_id', auth()->id());
            $userType = $request->input('user_type', 'customer');
            $eventType = $request->input('event_type');
            $eventData = $request->input('event_data', []);

            $success = $this->analyticsService->recordEvent(
                $userId,
                $eventType,
                $eventData,
                $userType
            );

            if ($success) {
                $this->loggingService->logAnalytics("Event recorded: {$eventType}", [
                    'user_id' => $userId,
                    'user_type' => $userType,
                    'event_data' => $eventData,
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Event recorded successfully',
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to record event',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Analytics event recording',
                'request_data' => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Get real-time analytics dashboard
     */
    public function getRealTimeAnalytics(Request $request): JsonResponse
    {
        try {
            $analytics = $this->analyticsService->getRealTimeAnalytics();

            if ($analytics) {
                return response()->json([
                    'success' => true,
                    'data' => $analytics,
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to get real-time analytics',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Real-time analytics retrieval',
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Get seller analytics
     */
    public function getSellerAnalytics(Request $request, $sellerId = null): JsonResponse
    {
        try {
            $sellerId = $sellerId ?: auth()->id();
            $period = $request->input('period', 'last_30_days');

            // Validate access (sellers can only see their own analytics)
            if (auth()->user()->user_type === 'seller' && auth()->id() != $sellerId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized access',
                ], 403);
            }

            $analytics = $this->analyticsService->getSellerAnalytics($sellerId, $period);

            if ($analytics) {
                $this->loggingService->logAnalytics("Seller analytics accessed", [
                    'seller_id' => $sellerId,
                    'period' => $period,
                    'accessed_by' => auth()->id(),
                ]);

                return response()->json([
                    'success' => true,
                    'data' => $analytics,
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to get seller analytics',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Seller analytics retrieval',
                'seller_id' => $sellerId,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Get customer analytics
     */
    public function getCustomerAnalytics(Request $request, $customerId = null): JsonResponse
    {
        try {
            $customerId = $customerId ?: auth()->id();
            $period = $request->input('period', 'last_30_days');

            // Validate access (customers can only see their own analytics)
            if (auth()->user()->user_type === 'customer' && auth()->id() != $customerId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized access',
                ], 403);
            }

            $analytics = $this->analyticsService->getCustomerAnalytics($customerId, $period);

            if ($analytics) {
                $this->loggingService->logAnalytics("Customer analytics accessed", [
                    'customer_id' => $customerId,
                    'period' => $period,
                    'accessed_by' => auth()->id(),
                ]);

                return response()->json([
                    'success' => true,
                    'data' => $analytics,
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to get customer analytics',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Customer analytics retrieval',
                'customer_id' => $customerId,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Get delivery analytics
     */
    public function getDeliveryAnalytics(Request $request, $deliveryPersonId = null): JsonResponse
    {
        try {
            $deliveryPersonId = $deliveryPersonId ?: auth()->id();
            $period = $request->input('period', 'last_30_days');

            // Validate access (delivery personnel can only see their own analytics)
            if (auth()->user()->user_type === 'delivery' && auth()->id() != $deliveryPersonId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized access',
                ], 403);
            }

            $analytics = $this->analyticsService->getDeliveryAnalytics($deliveryPersonId, $period);

            if ($analytics) {
                $this->loggingService->logAnalytics("Delivery analytics accessed", [
                    'delivery_person_id' => $deliveryPersonId,
                    'period' => $period,
                    'accessed_by' => auth()->id(),
                ]);

                return response()->json([
                    'success' => true,
                    'data' => $analytics,
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to get delivery analytics',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Delivery analytics retrieval',
                'delivery_person_id' => $deliveryPersonId,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Get platform analytics (admin only)
     */
    public function getPlatformAnalytics(Request $request): JsonResponse
    {
        try {
            // Check admin access
            if (auth()->user()->user_type !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin access required',
                ], 403);
            }

            $period = $request->input('period', 'last_30_days');
            $analytics = $this->analyticsService->getPlatformAnalytics($period);

            if ($analytics) {
                $this->loggingService->logAnalytics("Platform analytics accessed", [
                    'period' => $period,
                    'accessed_by' => auth()->id(),
                ]);

                return response()->json([
                    'success' => true,
                    'data' => $analytics,
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to get platform analytics',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Platform analytics retrieval',
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Generate analytics report
     */
    public function generateReport(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'type' => 'required|string|in:seller_monthly,platform_weekly,delivery_daily',
                'params' => 'nullable|array',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $type = $request->input('type');
            $params = $request->input('params', []);

            // Check permissions based on report type
            if (str_contains($type, 'platform') && auth()->user()->user_type !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin access required for platform reports',
                ], 403);
            }

            $report = $this->analyticsService->generateReport($type, $params);

            if ($report) {
                $this->loggingService->logAnalytics("Analytics report generated", [
                    'report_type' => $type,
                    'report_id' => $report['report_id'],
                    'generated_by' => auth()->id(),
                ]);

                return response()->json([
                    'success' => true,
                    'data' => $report,
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to generate report',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Analytics report generation',
                'request_data' => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Clear analytics cache
     */
    public function clearCache(Request $request): JsonResponse
    {
        try {
            // Admin only
            if (auth()->user()->user_type !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin access required',
                ], 403);
            }

            $type = $request->input('type');
            $id = $request->input('id');

            $this->analyticsService->clearCache($type, $id);

            $this->loggingService->logAnalytics("Analytics cache cleared", [
                'type' => $type,
                'id' => $id,
                'cleared_by' => auth()->id(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Cache cleared successfully',
            ]);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Analytics cache clearing',
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }
}