<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Cache;
use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;
use Ratchet\RFC6455\Messaging\MessageInterface;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class WebSocketService implements MessageComponentInterface
{
    protected $clients;
    protected $channels;
    protected $userConnections;
    protected $statistics;

    public function __construct()
    {
        $this->clients = new \SplObjectStorage;
        $this->channels = [];
        $this->userConnections = [];
        $this->statistics = [
            'total_connections' => 0,
            'active_connections' => 0,
            'messages_sent' => 0,
            'messages_received' => 0,
            'channels_active' => 0,
            'errors_count' => 0,
        ];

        Log::info('WebSocket Service initialized');
    }

    public function onOpen(ConnectionInterface $conn)
    {
        try {
            // Parse query parameters for authentication
            $query = $conn->httpRequest->getUri()->getQuery();
            parse_str($query, $params);

            // Authenticate user
            $user = $this->authenticateConnection($params);
            if (!$user) {
                $conn->close(1008, 'Authentication failed');
                return;
            }

            // Store connection info
            $conn->user = $user;
            $conn->userId = $user->id;
            $conn->userType = $params['type'] ?? 'customer';
            $conn->resourceId = $conn->resourceId;
            $conn->connectedAt = now();

            // Add to clients
            $this->clients->attach($conn);
            
            // Track user connections
            $this->userConnections[$user->id] = $conn;

            // Update statistics
            $this->statistics['total_connections']++;
            $this->statistics['active_connections']++;

            // Send connection confirmation
            $this->sendMessage($conn, [
                'type' => 'connection_confirmed',
                'user_id' => $user->id,
                'user_type' => $conn->userType,
                'connected_at' => $conn->connectedAt->toISOString(),
                'server_time' => now()->toISOString(),
            ]);

            // Subscribe to user-specific channels based on type
            $this->subscribeToUserChannels($conn);

            // Broadcast user online status
            $this->broadcastUserStatus($user->id, $conn->userType, true);

            Log::info("WebSocket connection opened", [
                'user_id' => $user->id,
                'user_type' => $conn->userType,
                'resource_id' => $conn->resourceId,
                'ip' => $conn->remoteAddress,
            ]);

        } catch (\Exception $e) {
            Log::error("WebSocket connection error: " . $e->getMessage());
            $conn->close(1011, 'Internal server error');
        }
    }

    public function onMessage(ConnectionInterface $from, $msg)
    {
        try {
            $this->statistics['messages_received']++;
            
            $data = json_decode($msg, true);
            if (!$data) {
                $this->sendError($from, 'Invalid JSON message');
                return;
            }

            $messageType = $data['type'] ?? null;
            if (!$messageType) {
                $this->sendError($from, 'Message type is required');
                return;
            }

            Log::debug("WebSocket message received", [
                'user_id' => $from->userId,
                'type' => $messageType,
                'data' => $data,
            ]);

            // Handle different message types
            switch ($messageType) {
                case 'ping':
                    $this->handlePing($from, $data);
                    break;

                case 'subscribe':
                    $this->handleSubscribe($from, $data);
                    break;

                case 'unsubscribe':
                    $this->handleUnsubscribe($from, $data);
                    break;

                case 'order_status_update':
                    $this->handleOrderStatusUpdate($from, $data);
                    break;

                case 'location_update':
                    $this->handleLocationUpdate($from, $data);
                    break;

                case 'chat_message':
                    $this->handleChatMessage($from, $data);
                    break;

                case 'delivery_status_update':
                    $this->handleDeliveryStatusUpdate($from, $data);
                    break;

                case 'inventory_update':
                    $this->handleInventoryUpdate($from, $data);
                    break;

                case 'emergency_alert':
                    $this->handleEmergencyAlert($from, $data);
                    break;

                case 'request_route_optimization':
                    $this->handleRouteOptimization($from, $data);
                    break;

                default:
                    $this->sendError($from, "Unknown message type: $messageType");
            }

        } catch (\Exception $e) {
            Log::error("WebSocket message handling error: " . $e->getMessage());
            $this->sendError($from, 'Message processing failed');
            $this->statistics['errors_count']++;
        }
    }

    public function onClose(ConnectionInterface $conn)
    {
        // Remove from clients
        $this->clients->detach($conn);

        // Update statistics
        $this->statistics['active_connections']--;

        if (isset($conn->userId)) {
            // Remove from user connections
            unset($this->userConnections[$conn->userId]);

            // Unsubscribe from all channels
            $this->unsubscribeFromAllChannels($conn);

            // Broadcast user offline status
            $this->broadcastUserStatus($conn->userId, $conn->userType ?? 'unknown', false);

            Log::info("WebSocket connection closed", [
                'user_id' => $conn->userId,
                'user_type' => $conn->userType ?? 'unknown',
                'resource_id' => $conn->resourceId,
                'duration' => $conn->connectedAt ? now()->diffInSeconds($conn->connectedAt) : 0,
            ]);
        }
    }

    public function onError(ConnectionInterface $conn, \Exception $e)
    {
        Log::error("WebSocket connection error", [
            'user_id' => $conn->userId ?? 'unknown',
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
        ]);

        $this->statistics['errors_count']++;
        $conn->close(1011);
    }

    // Authentication methods
    private function authenticateConnection($params)
    {
        try {
            $token = $params['token'] ?? null;
            if (!$token) {
                return null;
            }

            // Decode JWT token
            $jwtSecret = config('websocket.auth.jwt_secret');
            $decoded = JWT::decode($token, new Key($jwtSecret, 'HS256'));

            // Find user
            $user = User::find($decoded->sub);
            if (!$user || !$user->is_active) {
                return null;
            }

            return $user;

        } catch (\Exception $e) {
            Log::warning("WebSocket authentication failed: " . $e->getMessage());
            return null;
        }
    }

    // Message handling methods
    private function handlePing($conn, $data)
    {
        $this->sendMessage($conn, [
            'type' => 'pong',
            'timestamp' => now()->toISOString(),
            'server_status' => 'healthy',
        ]);
    }

    private function handleSubscribe($conn, $data)
    {
        $channel = $data['channel'] ?? null;
        if (!$channel) {
            $this->sendError($conn, 'Channel name is required');
            return;
        }

        // Validate channel access
        if (!$this->canAccessChannel($conn, $channel)) {
            $this->sendError($conn, 'Access denied to channel');
            return;
        }

        // Add to channel
        if (!isset($this->channels[$channel])) {
            $this->channels[$channel] = new \SplObjectStorage;
            $this->statistics['channels_active']++;
        }

        $this->channels[$channel]->attach($conn);

        // Confirm subscription
        $this->sendMessage($conn, [
            'type' => 'subscribed',
            'channel' => $channel,
            'timestamp' => now()->toISOString(),
        ]);

        Log::debug("User subscribed to channel", [
            'user_id' => $conn->userId,
            'channel' => $channel,
        ]);
    }

    private function handleUnsubscribe($conn, $data)
    {
        $channel = $data['channel'] ?? null;
        if (!$channel || !isset($this->channels[$channel])) {
            return;
        }

        $this->channels[$channel]->detach($conn);

        // Remove empty channels
        if ($this->channels[$channel]->count() === 0) {
            unset($this->channels[$channel]);
            $this->statistics['channels_active']--;
        }

        $this->sendMessage($conn, [
            'type' => 'unsubscribed',
            'channel' => $channel,
            'timestamp' => now()->toISOString(),
        ]);
    }

    private function handleOrderStatusUpdate($conn, $data)
    {
        $orderId = $data['order_id'] ?? null;
        $status = $data['status'] ?? null;

        if (!$orderId || !$status) {
            $this->sendError($conn, 'Order ID and status are required');
            return;
        }

        // Broadcast to order channel
        $this->broadcastToChannel("orders.{$orderId}", [
            'type' => 'order_update',
            'order_id' => $orderId,
            'status' => $status,
            'notes' => $data['notes'] ?? null,
            'metadata' => $data['metadata'] ?? null,
            'updated_by' => $conn->userType,
            'updated_by_id' => $conn->userId,
            'timestamp' => now()->toISOString(),
        ]);

        // Store in database
        $this->storeOrderUpdate($orderId, $status, $data);
    }

    private function handleLocationUpdate($conn, $data)
    {
        if ($conn->userType !== 'delivery') {
            $this->sendError($conn, 'Only delivery personnel can update location');
            return;
        }

        $latitude = $data['latitude'] ?? null;
        $longitude = $data['longitude'] ?? null;

        if (!$latitude || !$longitude) {
            $this->sendError($conn, 'Latitude and longitude are required');
            return;
        }

        // Update Redis with current location
        Redis::hset("delivery_location:{$conn->userId}", [
            'latitude' => $latitude,
            'longitude' => $longitude,
            'accuracy' => $data['accuracy'] ?? 0,
            'speed' => $data['speed'] ?? 0,
            'heading' => $data['heading'] ?? 0,
            'timestamp' => now()->toISOString(),
        ]);

        Redis::expire("delivery_location:{$conn->userId}", 3600); // 1 hour

        // Broadcast to location channel
        $this->broadcastToChannel("location.{$conn->userId}", [
            'type' => 'location_update',
            'delivery_person_id' => $conn->userId,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'accuracy' => $data['accuracy'] ?? 0,
            'speed' => $data['speed'] ?? 0,
            'heading' => $data['heading'] ?? 0,
            'timestamp' => now()->toISOString(),
        ]);
    }

    private function handleChatMessage($conn, $data)
    {
        $chatId = $data['chat_id'] ?? null;
        $message = $data['message'] ?? null;

        if (!$chatId || !$message) {
            $this->sendError($conn, 'Chat ID and message are required');
            return;
        }

        // Broadcast to chat channel
        $this->broadcastToChannel("chat.{$chatId}", [
            'type' => 'chat_message',
            'chat_id' => $chatId,
            'message' => $message,
            'sender_id' => $conn->userId,
            'sender_type' => $conn->userType,
            'message_type' => $data['message_type'] ?? 'text',
            'metadata' => $data['metadata'] ?? null,
            'timestamp' => now()->toISOString(),
        ]);

        // Store message in database
        $this->storeChatMessage($chatId, $conn->userId, $message, $data);
    }

    private function handleDeliveryStatusUpdate($conn, $data)
    {
        if ($conn->userType !== 'delivery') {
            $this->sendError($conn, 'Only delivery personnel can update delivery status');
            return;
        }

        $deliveryId = $data['delivery_id'] ?? null;
        $status = $data['status'] ?? null;

        if (!$deliveryId || !$status) {
            $this->sendError($conn, 'Delivery ID and status are required');
            return;
        }

        // Broadcast to delivery channel
        $this->broadcastToChannel("deliveries.{$conn->userId}", [
            'type' => 'delivery_update',
            'delivery_id' => $deliveryId,
            'status' => $status,
            'notes' => $data['notes'] ?? null,
            'metadata' => $data['metadata'] ?? null,
            'delivery_person_id' => $conn->userId,
            'timestamp' => now()->toISOString(),
        ]);

        // Update database
        $this->storeDeliveryUpdate($deliveryId, $status, $data);
    }

    private function handleInventoryUpdate($conn, $data)
    {
        if ($conn->userType !== 'seller') {
            $this->sendError($conn, 'Only sellers can update inventory');
            return;
        }

        $productId = $data['product_id'] ?? null;
        $quantity = $data['quantity'] ?? null;

        if (!$productId || !is_numeric($quantity)) {
            $this->sendError($conn, 'Product ID and quantity are required');
            return;
        }

        // Broadcast to inventory channel
        $this->broadcastToChannel("inventory.seller.{$conn->userId}", [
            'type' => 'inventory_update',
            'product_id' => $productId,
            'quantity' => $quantity,
            'is_available' => $data['is_available'] ?? true,
            'price' => $data['price'] ?? null,
            'metadata' => $data['metadata'] ?? null,
            'seller_id' => $conn->userId,
            'timestamp' => now()->toISOString(),
        ]);

        // Update database
        $this->storeInventoryUpdate($productId, $quantity, $data);
    }

    private function handleEmergencyAlert($conn, $data)
    {
        if ($conn->userType !== 'delivery') {
            $this->sendError($conn, 'Only delivery personnel can send emergency alerts');
            return;
        }

        $alertType = $data['alert_type'] ?? null;
        $description = $data['description'] ?? null;

        if (!$alertType || !$description) {
            $this->sendError($conn, 'Alert type and description are required');
            return;
        }

        // Broadcast emergency alert to admin channels
        $this->broadcastToChannel('system.admin', [
            'type' => 'emergency_alert',
            'alert_type' => $alertType,
            'description' => $description,
            'delivery_person_id' => $conn->userId,
            'latitude' => $data['latitude'] ?? null,
            'longitude' => $data['longitude'] ?? null,
            'timestamp' => now()->toISOString(),
            'priority' => 'critical',
        ]);

        // Store alert in database
        $this->storeEmergencyAlert($conn->userId, $alertType, $description, $data);

        Log::critical("Emergency alert received", [
            'delivery_person_id' => $conn->userId,
            'alert_type' => $alertType,
            'description' => $description,
            'location' => [
                'latitude' => $data['latitude'] ?? null,
                'longitude' => $data['longitude'] ?? null,
            ],
        ]);
    }

    private function handleRouteOptimization($conn, $data)
    {
        if ($conn->userType !== 'delivery') {
            $this->sendError($conn, 'Only delivery personnel can request route optimization');
            return;
        }

        $deliveryIds = $data['delivery_ids'] ?? [];
        if (empty($deliveryIds)) {
            $this->sendError($conn, 'Delivery IDs are required');
            return;
        }

        // Queue route optimization job
        dispatch(new \App\Jobs\OptimizeDeliveryRoute($conn->userId, $deliveryIds, $data));

        $this->sendMessage($conn, [
            'type' => 'route_optimization_queued',
            'delivery_ids' => $deliveryIds,
            'estimated_processing_time' => 30, // seconds
            'timestamp' => now()->toISOString(),
        ]);
    }

    // Utility methods
    private function subscribeToUserChannels($conn)
    {
        $userType = $conn->userType;
        $userId = $conn->userId;

        switch ($userType) {
            case 'customer':
                $channels = [
                    "notifications.customer.{$userId}",
                    "chat.customer.{$userId}",
                ];
                break;

            case 'seller':
                $channels = [
                    "orders.seller.{$userId}",
                    "inventory.seller.{$userId}",
                    "notifications.seller.{$userId}",
                    "chat.seller.{$userId}",
                    "analytics.seller.{$userId}",
                ];
                break;

            case 'delivery':
                $channels = [
                    "deliveries.{$userId}",
                    "routes.{$userId}",
                    "location.{$userId}",
                    "notifications.delivery.{$userId}",
                ];
                break;

            default:
                $channels = [];
        }

        foreach ($channels as $channel) {
            if (!isset($this->channels[$channel])) {
                $this->channels[$channel] = new \SplObjectStorage;
                $this->statistics['channels_active']++;
            }
            $this->channels[$channel]->attach($conn);
        }
    }

    private function unsubscribeFromAllChannels($conn)
    {
        foreach ($this->channels as $channel => $connections) {
            if ($connections->contains($conn)) {
                $connections->detach($conn);
                if ($connections->count() === 0) {
                    unset($this->channels[$channel]);
                    $this->statistics['channels_active']--;
                }
            }
        }
    }

    private function canAccessChannel($conn, $channel)
    {
        $userType = $conn->userType;
        $userId = $conn->userId;

        // Check channel permissions based on user type and channel pattern
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

    private function broadcastToChannel($channel, $data)
    {
        if (!isset($this->channels[$channel])) {
            return;
        }

        $message = json_encode($data);
        
        foreach ($this->channels[$channel] as $conn) {
            try {
                $conn->send($message);
                $this->statistics['messages_sent']++;
            } catch (\Exception $e) {
                Log::warning("Failed to send message to connection", [
                    'user_id' => $conn->userId ?? 'unknown',
                    'channel' => $channel,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        Log::debug("Message broadcasted to channel", [
            'channel' => $channel,
            'recipient_count' => $this->channels[$channel]->count(),
            'message_type' => $data['type'] ?? 'unknown',
        ]);
    }

    private function broadcastUserStatus($userId, $userType, $isOnline)
    {
        $statusData = [
            'type' => 'user_status_update',
            'user_id' => $userId,
            'user_type' => $userType,
            'is_online' => $isOnline,
            'timestamp' => now()->toISOString(),
        ];

        // Broadcast to relevant channels based on user type
        switch ($userType) {
            case 'delivery':
                $this->broadcastToChannel('system.admin', $statusData);
                break;
            case 'seller':
                $this->broadcastToChannel('system.admin', $statusData);
                break;
        }

        // Store status in Redis
        if ($isOnline) {
            Redis::hset("user_status:{$userId}", [
                'is_online' => true,
                'user_type' => $userType,
                'last_seen' => now()->toISOString(),
            ]);
            Redis::expire("user_status:{$userId}", 300); // 5 minutes
        } else {
            Redis::hset("user_status:{$userId}", [
                'is_online' => false,
                'user_type' => $userType,
                'last_seen' => now()->toISOString(),
            ]);
        }
    }

    private function sendMessage($conn, $data)
    {
        try {
            $conn->send(json_encode($data));
            $this->statistics['messages_sent']++;
        } catch (\Exception $e) {
            Log::warning("Failed to send message to connection", [
                'user_id' => $conn->userId ?? 'unknown',
                'error' => $e->getMessage(),
            ]);
        }
    }

    private function sendError($conn, $message)
    {
        $this->sendMessage($conn, [
            'type' => 'error',
            'message' => $message,
            'timestamp' => now()->toISOString(),
        ]);
    }

    // Database storage methods
    private function storeOrderUpdate($orderId, $status, $data)
    {
        // Implementation for storing order updates
        // This would typically update the orders table and create audit logs
    }

    private function storeChatMessage($chatId, $senderId, $message, $data)
    {
        // Implementation for storing chat messages
        // This would typically create a record in the chat_messages table
    }

    private function storeDeliveryUpdate($deliveryId, $status, $data)
    {
        // Implementation for storing delivery updates
        // This would typically update the deliveries table and create status logs
    }

    private function storeInventoryUpdate($productId, $quantity, $data)
    {
        // Implementation for storing inventory updates
        // This would typically update the products table and create inventory logs
    }

    private function storeEmergencyAlert($deliveryPersonId, $alertType, $description, $data)
    {
        // Implementation for storing emergency alerts
        // This would typically create a record in the emergency_alerts table
    }

    // Statistics and monitoring
    public function getStatistics()
    {
        return array_merge($this->statistics, [
            'channels' => array_keys($this->channels),
            'active_users' => count($this->userConnections),
            'uptime' => now()->toISOString(),
        ]);
    }
}