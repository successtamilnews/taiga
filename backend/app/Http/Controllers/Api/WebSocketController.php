<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\BroadcastService;
use App\Services\LoggingService;
use App\Services\WebSocketService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Redis;

class WebSocketController extends Controller
{
    protected $broadcastService;
    protected $loggingService;

    public function __construct(BroadcastService $broadcastService, LoggingService $loggingService)
    {
        $this->broadcastService = $broadcastService;
        $this->loggingService = $loggingService;
    }

    /**
     * Broadcast message to specific channel
     */
    public function broadcast(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'channel' => 'required|string',
                'data' => 'required|array',
                'data.type' => 'required|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $channel = $request->input('channel');
            $data = $request->input('data');

            // Validate channel access permissions
            if (!$this->canAccessChannel(auth()->user(), $channel)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Access denied to channel',
                ], 403);
            }

            // Send broadcast
            $success = $this->sendToChannel($channel, $data);

            if ($success) {
                $this->loggingService->logWebSocket("Message broadcasted", [
                    'channel' => $channel,
                    'message_type' => $data['type'],
                    'sent_by' => auth()->id(),
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Message broadcasted successfully',
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to broadcast message',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'WebSocket broadcasting',
                'request_data' => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Broadcast order update
     */
    public function broadcastOrderUpdate(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'order_id' => 'required|integer|exists:orders,id',
                'status' => 'required|string',
                'metadata' => 'nullable|array',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $orderId = $request->input('order_id');
            $status = $request->input('status');
            $metadata = $request->input('metadata', []);

            // Get order
            $order = \App\Models\Order::find($orderId);
            if (!$order) {
                return response()->json([
                    'success' => false,
                    'message' => 'Order not found',
                ], 404);
            }

            // Broadcast order update
            $success = $this->broadcastService->broadcastOrderUpdate($order, $status, $metadata);

            if ($success) {
                $this->loggingService->logOrder("Order update broadcasted", $orderId, [
                    'status' => $status,
                    'metadata' => $metadata,
                    'broadcasted_by' => auth()->id(),
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Order update broadcasted successfully',
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to broadcast order update',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Order update broadcasting',
                'request_data' => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Broadcast delivery tracking update
     */
    public function broadcastDeliveryTracking(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'delivery_person_id' => 'required|integer|exists:users,id',
                'order_id' => 'required|integer|exists:orders,id',
                'location' => 'required|array',
                'location.latitude' => 'required|numeric',
                'location.longitude' => 'required|numeric',
                'status' => 'nullable|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $deliveryPersonId = $request->input('delivery_person_id');
            $orderId = $request->input('order_id');
            $location = $request->input('location');
            $status = $request->input('status');

            // Validate delivery person access
            if (auth()->user()->user_type === 'delivery' && auth()->id() != $deliveryPersonId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized access',
                ], 403);
            }

            // Broadcast delivery tracking update
            $success = $this->broadcastService->broadcastDeliveryTrackingUpdate(
                $deliveryPersonId, 
                $orderId, 
                $location, 
                $status
            );

            if ($success) {
                $this->loggingService->logDelivery("Delivery tracking update broadcasted", $orderId, [
                    'delivery_person_id' => $deliveryPersonId,
                    'location' => $location,
                    'status' => $status,
                    'broadcasted_by' => auth()->id(),
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Delivery tracking update broadcasted successfully',
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to broadcast delivery tracking update',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Delivery tracking broadcasting',
                'request_data' => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Broadcast emergency alert
     */
    public function broadcastEmergencyAlert(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'delivery_person_id' => 'required|integer|exists:users,id',
                'alert_type' => 'required|string',
                'description' => 'required|string',
                'location' => 'required|array',
                'location.latitude' => 'required|numeric',
                'location.longitude' => 'required|numeric',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $deliveryPersonId = $request->input('delivery_person_id');
            $alertType = $request->input('alert_type');
            $description = $request->input('description');
            $location = $request->input('location');

            // Validate delivery person access
            if (auth()->user()->user_type === 'delivery' && auth()->id() != $deliveryPersonId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized access',
                ], 403);
            }

            // Broadcast emergency alert
            $success = $this->broadcastService->broadcastEmergencyAlert(
                $deliveryPersonId,
                $alertType,
                $location,
                $description
            );

            if ($success) {
                $this->loggingService->logEmergency("Emergency alert broadcasted", 'critical', [
                    'delivery_person_id' => $deliveryPersonId,
                    'alert_type' => $alertType,
                    'description' => $description,
                    'location' => $location,
                    'broadcasted_by' => auth()->id(),
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Emergency alert broadcasted successfully',
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to broadcast emergency alert',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Emergency alert broadcasting',
                'request_data' => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Send chat message
     */
    public function sendChatMessage(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'chat_id' => 'required|string',
                'receiver_id' => 'required|integer|exists:users,id',
                'message' => 'required|string',
                'message_type' => 'nullable|string|in:text,image,file,location',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $chatId = $request->input('chat_id');
            $receiverId = $request->input('receiver_id');
            $message = $request->input('message');
            $messageType = $request->input('message_type', 'text');

            // Broadcast chat message
            $success = $this->broadcastService->broadcastChatMessage(
                $chatId,
                auth()->id(),
                $receiverId,
                $message,
                $messageType
            );

            if ($success) {
                $this->loggingService->logWebSocket("Chat message sent", [
                    'chat_id' => $chatId,
                    'sender_id' => auth()->id(),
                    'receiver_id' => $receiverId,
                    'message_type' => $messageType,
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Chat message sent successfully',
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to send chat message',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'Chat message sending',
                'request_data' => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Get WebSocket server statistics
     */
    public function getServerStatistics(): JsonResponse
    {
        try {
            // Admin only
            if (auth()->user()->user_type !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin access required',
                ], 403);
            }

            $statistics = $this->broadcastService->getServerStatistics();

            if ($statistics) {
                return response()->json([
                    'success' => true,
                    'data' => $statistics,
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to get server statistics',
            ], 500);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'WebSocket server statistics retrieval',
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    /**
     * Check WebSocket server health
     */
    public function checkServerHealth(): JsonResponse
    {
        try {
            $isHealthy = $this->broadcastService->isServerHealthy();

            return response()->json([
                'success' => true,
                'data' => [
                    'status' => $isHealthy ? 'healthy' : 'unhealthy',
                    'timestamp' => now()->toISOString(),
                ],
            ]);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'WebSocket server health check',
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
                'data' => [
                    'status' => 'unhealthy',
                    'timestamp' => now()->toISOString(),
                ],
            ], 500);
        }
    }

    /**
     * Get user's online status
     */
    public function getUserStatus(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'user_ids' => 'required|array',
                'user_ids.*' => 'integer|exists:users,id',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $userIds = $request->input('user_ids');
            $statuses = [];

            foreach ($userIds as $userId) {
                $status = Redis::hgetall("user_status:{$userId}");
                $statuses[$userId] = [
                    'user_id' => $userId,
                    'is_online' => (bool) ($status['is_online'] ?? false),
                    'user_type' => $status['user_type'] ?? 'unknown',
                    'last_seen' => $status['last_seen'] ?? null,
                ];
            }

            return response()->json([
                'success' => true,
                'data' => $statuses,
            ]);

        } catch (\Exception $e) {
            $this->loggingService->logError($e, [
                'context' => 'User status retrieval',
                'request_data' => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
            ], 500);
        }
    }

    // Helper methods

    protected function canAccessChannel($user, $channel)
    {
        $userType = $user->user_type;
        $userId = $user->id;

        // Get allowed channel patterns for user type
        $allowedPatterns = config("websocket.channels.{$userType}", []);
        
        foreach ($allowedPatterns as $pattern) {
            $regex = str_replace(['{user_id}', '{customer_id}', '{seller_id}', '{delivery_person_id}', '{order_id}', '{zone_id}'], 
                               ['\d+', '\d+', '\d+', '\d+', '\d+', '\w+'], $pattern);
            $regex = '/^' . str_replace('.', '\.', $regex) . '$/';
            
            if (preg_match($regex, $channel)) {
                // Additional check for user-specific channels
                if (strpos($pattern, '{user_id}') !== false || 
                    strpos($pattern, "{{$userType}_id}") !== false) {
                    return strpos($channel, ".{$userId}") !== false;
                }
                return true;
            }
        }

        return false;
    }

    protected function sendToChannel($channel, $data)
    {
        try {
            // This would integrate with your WebSocket server
            // For now, we'll use Redis for demonstration
            Redis::publish("websocket_channel:{$channel}", json_encode($data));
            
            return true;
        } catch (\Exception $e) {
            return false;
        }
    }
}