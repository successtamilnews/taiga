<?php

namespace App\Services;

use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Log;
use App\Models\Order;
use App\Models\User;
use App\Models\Product;

class BroadcastService
{
    protected $websocketUrl;
    protected $apiSecret;

    public function __construct()
    {
        $this->websocketUrl = config('websocket.server.broadcast_url');
        $this->apiSecret = config('websocket.auth.api_secret');
    }

    /**
     * Broadcast order status update to all relevant parties
     */
    public function broadcastOrderUpdate($order, $status, $metadata = [])
    {
        try {
            $orderData = [
                'type' => 'order_update',
                'order_id' => $order->id,
                'customer_id' => $order->customer_id,
                'seller_id' => $order->seller_id,
                'delivery_person_id' => $order->delivery_person_id,
                'status' => $status,
                'total_amount' => $order->total_amount,
                'metadata' => $metadata,
                'timestamp' => now()->toISOString(),
            ];

            // Broadcast to customer
            $this->sendToChannel("notifications.customer.{$order->customer_id}", $orderData);

            // Broadcast to seller
            $this->sendToChannel("orders.seller.{$order->seller_id}", $orderData);

            // Broadcast to delivery person if assigned
            if ($order->delivery_person_id) {
                $this->sendToChannel("deliveries.{$order->delivery_person_id}", $orderData);
            }

            // Broadcast to admin
            $this->sendToChannel('system.admin', $orderData);

            Log::info('Order update broadcasted', [
                'order_id' => $order->id,
                'status' => $status,
                'recipients' => ['customer', 'seller', 'delivery', 'admin'],
            ]);

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to broadcast order update: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Broadcast new order notification
     */
    public function broadcastNewOrder($order)
    {
        try {
            $orderData = [
                'type' => 'new_order',
                'order_id' => $order->id,
                'customer_id' => $order->customer_id,
                'seller_id' => $order->seller_id,
                'total_amount' => $order->total_amount,
                'items_count' => $order->items->count(),
                'delivery_address' => $order->delivery_address,
                'special_instructions' => $order->special_instructions,
                'timestamp' => now()->toISOString(),
            ];

            // Notify seller
            $this->sendToChannel("orders.seller.{$order->seller_id}", $orderData);
            
            // Notify delivery zone (for available delivery personnel)
            if ($order->delivery_zone_id) {
                $this->sendToChannel("zone.{$order->delivery_zone_id}", $orderData);
            }

            // Notify admin
            $this->sendToChannel('system.admin', $orderData);

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to broadcast new order: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Broadcast delivery tracking update
     */
    public function broadcastDeliveryTrackingUpdate($deliveryPersonId, $orderId, $location, $status = null)
    {
        try {
            $trackingData = [
                'type' => 'delivery_tracking_update',
                'order_id' => $orderId,
                'delivery_person_id' => $deliveryPersonId,
                'location' => $location,
                'status' => $status,
                'timestamp' => now()->toISOString(),
            ];

            // Get order to find customer
            $order = Order::find($orderId);
            if ($order) {
                // Notify customer
                $this->sendToChannel("notifications.customer.{$order->customer_id}", $trackingData);
                
                // Notify seller
                $this->sendToChannel("orders.seller.{$order->seller_id}", $trackingData);
            }

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to broadcast delivery tracking update: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Broadcast inventory update to customers and admin
     */
    public function broadcastInventoryUpdate($product, $oldQuantity, $newQuantity)
    {
        try {
            $inventoryData = [
                'type' => 'inventory_update',
                'product_id' => $product->id,
                'seller_id' => $product->seller_id,
                'old_quantity' => $oldQuantity,
                'new_quantity' => $newQuantity,
                'is_available' => $newQuantity > 0,
                'price' => $product->price,
                'name' => $product->name,
                'timestamp' => now()->toISOString(),
            ];

            // Notify users who have this product in wishlist or cart
            $this->notifyInterestedCustomers($product->id, $inventoryData);

            // Notify seller
            $this->sendToChannel("inventory.seller.{$product->seller_id}", $inventoryData);

            // Notify admin if product is out of stock
            if ($newQuantity <= 0) {
                $this->sendToChannel('system.admin', array_merge($inventoryData, [
                    'alert_type' => 'out_of_stock',
                    'requires_attention' => true,
                ]));
            }

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to broadcast inventory update: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Broadcast chat message
     */
    public function broadcastChatMessage($chatId, $senderId, $receiverId, $message, $messageType = 'text')
    {
        try {
            $chatData = [
                'type' => 'chat_message',
                'chat_id' => $chatId,
                'sender_id' => $senderId,
                'receiver_id' => $receiverId,
                'message' => $message,
                'message_type' => $messageType,
                'timestamp' => now()->toISOString(),
            ];

            // Send to both sender and receiver channels
            $this->sendToChannel("chat.{$chatId}", $chatData);

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to broadcast chat message: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Broadcast emergency alert
     */
    public function broadcastEmergencyAlert($deliveryPersonId, $alertType, $location, $description)
    {
        try {
            $alertData = [
                'type' => 'emergency_alert',
                'delivery_person_id' => $deliveryPersonId,
                'alert_type' => $alertType,
                'location' => $location,
                'description' => $description,
                'priority' => 'critical',
                'requires_immediate_action' => true,
                'timestamp' => now()->toISOString(),
            ];

            // Notify all admin channels
            $this->sendToChannel('system.admin', $alertData);
            
            // Notify emergency response team
            $this->sendToChannel('emergency.response', $alertData);

            // Store in Redis for dashboard alerts
            Redis::zadd('emergency_alerts', now()->timestamp, json_encode($alertData));
            Redis::expire('emergency_alerts', 86400); // 24 hours

            Log::critical('Emergency alert broadcasted', [
                'delivery_person_id' => $deliveryPersonId,
                'alert_type' => $alertType,
                'location' => $location,
            ]);

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to broadcast emergency alert: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Broadcast system notification
     */
    public function broadcastSystemNotification($userType, $userId, $title, $message, $actionData = [])
    {
        try {
            $notificationData = [
                'type' => 'system_notification',
                'user_type' => $userType,
                'user_id' => $userId,
                'title' => $title,
                'message' => $message,
                'action_data' => $actionData,
                'timestamp' => now()->toISOString(),
            ];

            // Send to user-specific notification channel
            $this->sendToChannel("notifications.{$userType}.{$userId}", $notificationData);

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to broadcast system notification: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Broadcast promotion/offer update
     */
    public function broadcastPromotionUpdate($promotion, $targetUserType = null, $targetUserIds = [])
    {
        try {
            $promotionData = [
                'type' => 'promotion_update',
                'promotion_id' => $promotion->id,
                'title' => $promotion->title,
                'description' => $promotion->description,
                'discount_percentage' => $promotion->discount_percentage,
                'valid_until' => $promotion->valid_until,
                'applicable_products' => $promotion->applicable_products,
                'minimum_order_amount' => $promotion->minimum_order_amount,
                'timestamp' => now()->toISOString(),
            ];

            if ($targetUserType && !empty($targetUserIds)) {
                // Send to specific users
                foreach ($targetUserIds as $userId) {
                    $this->sendToChannel("notifications.{$targetUserType}.{$userId}", $promotionData);
                }
            } else {
                // Broadcast to all users based on promotion scope
                $channels = $this->getPromotionBroadcastChannels($promotion);
                foreach ($channels as $channel) {
                    $this->sendToChannel($channel, $promotionData);
                }
            }

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to broadcast promotion update: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Broadcast seller analytics update
     */
    public function broadcastSellerAnalytics($sellerId, $analyticsData)
    {
        try {
            $analytics = [
                'type' => 'analytics_update',
                'seller_id' => $sellerId,
                'data' => $analyticsData,
                'timestamp' => now()->toISOString(),
            ];

            $this->sendToChannel("analytics.seller.{$sellerId}", $analytics);

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to broadcast seller analytics: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Broadcast route optimization result
     */
    public function broadcastRouteOptimization($deliveryPersonId, $optimizedRoute, $estimatedTime, $distanceSaved)
    {
        try {
            $routeData = [
                'type' => 'route_optimization_complete',
                'delivery_person_id' => $deliveryPersonId,
                'optimized_route' => $optimizedRoute,
                'estimated_time' => $estimatedTime,
                'distance_saved' => $distanceSaved,
                'fuel_savings' => $this->calculateFuelSavings($distanceSaved),
                'timestamp' => now()->toISOString(),
            ];

            $this->sendToChannel("routes.{$deliveryPersonId}", $routeData);

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to broadcast route optimization: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Send message to specific channel
     */
    protected function sendToChannel($channel, $data)
    {
        try {
            // Add channel to data
            $data['channel'] = $channel;

            // Send via HTTP API to WebSocket server
            $response = $this->sendHttpRequest('broadcast', [
                'channel' => $channel,
                'data' => $data,
            ]);

            if ($response && $response['success']) {
                Log::debug("Message sent to channel", [
                    'channel' => $channel,
                    'message_type' => $data['type'],
                ]);
                return true;
            }

            return false;

        } catch (\Exception $e) {
            Log::warning("Failed to send message to channel: " . $e->getMessage(), [
                'channel' => $channel,
                'data' => $data,
            ]);
            return false;
        }
    }

    /**
     * Send HTTP request to WebSocket server
     */
    protected function sendHttpRequest($endpoint, $data)
    {
        try {
            $url = rtrim($this->websocketUrl, '/') . '/' . ltrim($endpoint, '/');
            
            $headers = [
                'Content-Type: application/json',
                'Authorization: Bearer ' . $this->apiSecret,
                'X-API-Version: 1.0',
            ];

            $ch = curl_init();
            curl_setopt_array($ch, [
                CURLOPT_URL => $url,
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => json_encode($data),
                CURLOPT_HTTPHEADER => $headers,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT => 5,
                CURLOPT_CONNECTTIMEOUT => 2,
                CURLOPT_SSL_VERIFYPEER => false,
            ]);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $error = curl_error($ch);
            curl_close($ch);

            if ($error) {
                throw new \Exception("cURL error: " . $error);
            }

            if ($httpCode !== 200) {
                throw new \Exception("HTTP error: " . $httpCode);
            }

            return json_decode($response, true);

        } catch (\Exception $e) {
            Log::error("HTTP request to WebSocket server failed: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Notify customers interested in a product
     */
    protected function notifyInterestedCustomers($productId, $inventoryData)
    {
        try {
            // Get users who have this product in wishlist
            $wishlistUsers = Redis::smembers("product_wishlist:{$productId}");
            
            // Get users who have this product in cart
            $cartUsers = Redis::smembers("product_cart:{$productId}");
            
            $interestedUsers = array_unique(array_merge($wishlistUsers, $cartUsers));

            foreach ($interestedUsers as $userId) {
                $customData = array_merge($inventoryData, [
                    'notification_type' => 'product_availability',
                    'action_required' => $inventoryData['new_quantity'] > 0 ? 'available_now' : 'notify_when_available',
                ]);
                
                $this->sendToChannel("notifications.customer.{$userId}", $customData);
            }

        } catch (\Exception $e) {
            Log::warning("Failed to notify interested customers: " . $e->getMessage());
        }
    }

    /**
     * Get channels for promotion broadcast
     */
    protected function getPromotionBroadcastChannels($promotion)
    {
        $channels = [];

        if ($promotion->target_type === 'all_customers') {
            $channels[] = 'promotions.customers';
        } elseif ($promotion->target_type === 'specific_sellers') {
            foreach ($promotion->target_seller_ids as $sellerId) {
                $channels[] = "promotions.seller.{$sellerId}";
            }
        } elseif ($promotion->target_type === 'premium_customers') {
            $channels[] = 'promotions.premium_customers';
        }

        return $channels;
    }

    /**
     * Calculate fuel savings based on distance saved
     */
    protected function calculateFuelSavings($distanceSaved)
    {
        // Assume average fuel consumption and prices
        $avgFuelConsumption = 0.1; // liters per km
        $avgFuelPrice = 2.5; // per liter

        return [
            'distance_saved_km' => $distanceSaved,
            'fuel_saved_liters' => $distanceSaved * $avgFuelConsumption,
            'money_saved' => $distanceSaved * $avgFuelConsumption * $avgFuelPrice,
            'currency' => 'USD',
        ];
    }

    /**
     * Get WebSocket server statistics
     */
    public function getServerStatistics()
    {
        try {
            $response = $this->sendHttpRequest('stats', []);
            return $response['statistics'] ?? null;
        } catch (\Exception $e) {
            Log::error("Failed to get WebSocket server statistics: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Check if WebSocket server is healthy
     */
    public function isServerHealthy()
    {
        try {
            $response = $this->sendHttpRequest('health', []);
            return $response && $response['status'] === 'healthy';
        } catch (\Exception $e) {
            return false;
        }
    }
}