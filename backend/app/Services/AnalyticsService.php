<?php

namespace App\Services;

use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use App\Models\Order;
use App\Models\User;
use App\Models\Product;
use Carbon\Carbon;

class AnalyticsService
{
    protected $cachePrefix = 'analytics:';
    protected $cacheTtl = 3600; // 1 hour

    /**
     * Record user event for analytics
     */
    public function recordEvent($userId, $eventType, $eventData = [], $userType = 'customer')
    {
        try {
            $event = [
                'user_id' => $userId,
                'user_type' => $userType,
                'event_type' => $eventType,
                'event_data' => $eventData,
                'timestamp' => now()->toISOString(),
                'date' => now()->format('Y-m-d'),
                'hour' => now()->format('H'),
                'ip_address' => request()->ip(),
                'user_agent' => request()->userAgent(),
            ];

            // Store in Redis for real-time analytics
            Redis::zadd("events:real_time", now()->timestamp, json_encode($event));
            Redis::expire("events:real_time", 86400); // 24 hours

            // Store by event type for aggregation
            Redis::hincrby("events:count:daily:" . now()->format('Y-m-d'), $eventType, 1);
            Redis::expire("events:count:daily:" . now()->format('Y-m-d'), 86400 * 7); // 7 days

            // Store by user type
            Redis::hincrby("events:user_type:" . now()->format('Y-m-d'), $userType, 1);
            Redis::expire("events:user_type:" . now()->format('Y-m-d'), 86400 * 7);

            // Store by hour for hourly analytics
            Redis::hincrby("events:hourly:" . now()->format('Y-m-d:H'), $eventType, 1);
            Redis::expire("events:hourly:" . now()->format('Y-m-d:H'), 86400 * 3); // 3 days

            // Store user activity
            Redis::hset("user_activity:{$userId}", [
                'last_active' => now()->toISOString(),
                'last_event_type' => $eventType,
                'daily_events' => Redis::hincrby("user_daily_events:{$userId}:" . now()->format('Y-m-d'), $eventType, 1),
            ]);

            Log::debug('Analytics event recorded', [
                'user_id' => $userId,
                'event_type' => $eventType,
                'user_type' => $userType,
            ]);

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to record analytics event: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Get real-time analytics dashboard data
     */
    public function getRealTimeAnalytics()
    {
        try {
            $cacheKey = $this->cachePrefix . 'real_time';
            
            return Cache::remember($cacheKey, 300, function () { // 5 minutes cache
                $today = now()->format('Y-m-d');
                $currentHour = now()->format('H');

                return [
                    'current_time' => now()->toISOString(),
                    'active_users' => $this->getActiveUsersCount(),
                    'todays_stats' => $this->getTodaysStats(),
                    'hourly_stats' => $this->getHourlyStats($today),
                    'live_events' => $this->getLiveEvents(),
                    'user_types_distribution' => $this->getUserTypesDistribution($today),
                    'popular_events' => $this->getPopularEvents($today),
                    'conversion_rates' => $this->getConversionRates(),
                ];
            });

        } catch (\Exception $e) {
            Log::error('Failed to get real-time analytics: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Get seller analytics
     */
    public function getSellerAnalytics($sellerId, $period = 'last_30_days')
    {
        try {
            $cacheKey = $this->cachePrefix . "seller:{$sellerId}:{$period}";
            
            return Cache::remember($cacheKey, $this->cacheTtl, function () use ($sellerId, $period) {
                $dateRange = $this->getDateRange($period);
                
                return [
                    'period' => $period,
                    'date_range' => $dateRange,
                    'seller_id' => $sellerId,
                    'sales_overview' => $this->getSellerSalesOverview($sellerId, $dateRange),
                    'product_performance' => $this->getSellerProductPerformance($sellerId, $dateRange),
                    'customer_analytics' => $this->getSellerCustomerAnalytics($sellerId, $dateRange),
                    'revenue_trends' => $this->getSellerRevenueTrends($sellerId, $dateRange),
                    'order_analytics' => $this->getSellerOrderAnalytics($sellerId, $dateRange),
                    'inventory_insights' => $this->getSellerInventoryInsights($sellerId),
                    'customer_reviews' => $this->getSellerReviewsAnalytics($sellerId, $dateRange),
                    'marketing_performance' => $this->getSellerMarketingPerformance($sellerId, $dateRange),
                ];
            });

        } catch (\Exception $e) {
            Log::error('Failed to get seller analytics: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Get customer analytics
     */
    public function getCustomerAnalytics($customerId, $period = 'last_30_days')
    {
        try {
            $cacheKey = $this->cachePrefix . "customer:{$customerId}:{$period}";
            
            return Cache::remember($cacheKey, $this->cacheTtl, function () use ($customerId, $period) {
                $dateRange = $this->getDateRange($period);
                
                return [
                    'period' => $period,
                    'date_range' => $dateRange,
                    'customer_id' => $customerId,
                    'purchase_history' => $this->getCustomerPurchaseHistory($customerId, $dateRange),
                    'spending_patterns' => $this->getCustomerSpendingPatterns($customerId, $dateRange),
                    'favorite_categories' => $this->getCustomerFavoriteCategories($customerId, $dateRange),
                    'preferred_sellers' => $this->getCustomerPreferredSellers($customerId, $dateRange),
                    'app_usage' => $this->getCustomerAppUsage($customerId, $dateRange),
                    'loyalty_metrics' => $this->getCustomerLoyaltyMetrics($customerId),
                    'recommendations_performance' => $this->getCustomerRecommendationsPerformance($customerId, $dateRange),
                ];
            });

        } catch (\Exception $e) {
            Log::error('Failed to get customer analytics: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Get delivery analytics
     */
    public function getDeliveryAnalytics($deliveryPersonId, $period = 'last_30_days')
    {
        try {
            $cacheKey = $this->cachePrefix . "delivery:{$deliveryPersonId}:{$period}";
            
            return Cache::remember($cacheKey, $this->cacheTtl, function () use ($deliveryPersonId, $period) {
                $dateRange = $this->getDateRange($period);
                
                return [
                    'period' => $period,
                    'date_range' => $dateRange,
                    'delivery_person_id' => $deliveryPersonId,
                    'performance_overview' => $this->getDeliveryPerformanceOverview($deliveryPersonId, $dateRange),
                    'efficiency_metrics' => $this->getDeliveryEfficiencyMetrics($deliveryPersonId, $dateRange),
                    'route_analytics' => $this->getDeliveryRouteAnalytics($deliveryPersonId, $dateRange),
                    'earnings_breakdown' => $this->getDeliveryEarningsBreakdown($deliveryPersonId, $dateRange),
                    'customer_ratings' => $this->getDeliveryCustomerRatings($deliveryPersonId, $dateRange),
                    'working_hours' => $this->getDeliveryWorkingHours($deliveryPersonId, $dateRange),
                    'fuel_consumption' => $this->getDeliveryFuelConsumption($deliveryPersonId, $dateRange),
                ];
            });

        } catch (\Exception $e) {
            Log::error('Failed to get delivery analytics: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Get platform-wide analytics for admin
     */
    public function getPlatformAnalytics($period = 'last_30_days')
    {
        try {
            $cacheKey = $this->cachePrefix . "platform:{$period}";
            
            return Cache::remember($cacheKey, $this->cacheTtl, function () use ($period) {
                $dateRange = $this->getDateRange($period);
                
                return [
                    'period' => $period,
                    'date_range' => $dateRange,
                    'overview' => $this->getPlatformOverview($dateRange),
                    'user_growth' => $this->getUserGrowthAnalytics($dateRange),
                    'revenue_analytics' => $this->getRevenueAnalytics($dateRange),
                    'order_analytics' => $this->getOrderAnalytics($dateRange),
                    'seller_performance' => $this->getTopSellersAnalytics($dateRange),
                    'product_analytics' => $this->getProductAnalytics($dateRange),
                    'delivery_analytics' => $this->getDeliveryAnalytics($dateRange),
                    'geography_analytics' => $this->getGeographyAnalytics($dateRange),
                    'marketing_analytics' => $this->getMarketingAnalytics($dateRange),
                    'customer_satisfaction' => $this->getCustomerSatisfactionAnalytics($dateRange),
                ];
            });

        } catch (\Exception $e) {
            Log::error('Failed to get platform analytics: ' . $e->getMessage());
            return null;
        }
    }

    // Helper methods for analytics calculations

    protected function getActiveUsersCount()
    {
        // Users active in the last 5 minutes
        $activeThreshold = now()->subMinutes(5)->timestamp;
        
        return Redis::zcount('events:real_time', $activeThreshold, '+inf');
    }

    protected function getTodaysStats()
    {
        $today = now()->format('Y-m-d');
        $stats = Redis::hgetall("events:count:daily:{$today}");
        
        return [
            'page_views' => (int)($stats['page_view'] ?? 0),
            'orders_placed' => (int)($stats['order_placed'] ?? 0),
            'products_viewed' => (int)($stats['product_viewed'] ?? 0),
            'user_registrations' => (int)($stats['user_registered'] ?? 0),
            'searches_performed' => (int)($stats['search_performed'] ?? 0),
            'cart_additions' => (int)($stats['product_added_to_cart'] ?? 0),
        ];
    }

    protected function getHourlyStats($date)
    {
        $hourlyStats = [];
        
        for ($hour = 0; $hour < 24; $hour++) {
            $hourKey = $date . ':' . str_pad($hour, 2, '0', STR_PAD_LEFT);
            $stats = Redis::hgetall("events:hourly:{$hourKey}");
            
            $hourlyStats[] = [
                'hour' => $hour,
                'total_events' => array_sum($stats),
                'events' => $stats,
            ];
        }
        
        return $hourlyStats;
    }

    protected function getLiveEvents($limit = 50)
    {
        $events = Redis::zrevrange('events:real_time', 0, $limit - 1);
        
        return array_map(function ($event) {
            return json_decode($event, true);
        }, $events);
    }

    protected function getUserTypesDistribution($date)
    {
        return Redis::hgetall("events:user_type:{$date}");
    }

    protected function getPopularEvents($date)
    {
        $events = Redis::hgetall("events:count:daily:{$date}");
        arsort($events);
        
        return array_slice($events, 0, 10, true);
    }

    protected function getConversionRates()
    {
        $today = now()->format('Y-m-d');
        $stats = Redis::hgetall("events:count:daily:{$today}");
        
        $pageViews = (int)($stats['page_view'] ?? 0);
        $orders = (int)($stats['order_placed'] ?? 0);
        $cartAdditions = (int)($stats['product_added_to_cart'] ?? 0);
        
        return [
            'view_to_cart' => $pageViews > 0 ? ($cartAdditions / $pageViews) * 100 : 0,
            'cart_to_order' => $cartAdditions > 0 ? ($orders / $cartAdditions) * 100 : 0,
            'view_to_order' => $pageViews > 0 ? ($orders / $pageViews) * 100 : 0,
        ];
    }

    protected function getSellerSalesOverview($sellerId, $dateRange)
    {
        return DB::table('orders')
            ->where('seller_id', $sellerId)
            ->whereBetween('created_at', $dateRange)
            ->selectRaw('
                COUNT(*) as total_orders,
                SUM(total_amount) as total_revenue,
                AVG(total_amount) as average_order_value,
                COUNT(DISTINCT customer_id) as unique_customers
            ')
            ->first();
    }

    protected function getSellerProductPerformance($sellerId, $dateRange)
    {
        return DB::table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->join('products', 'order_items.product_id', '=', 'products.id')
            ->where('products.seller_id', $sellerId)
            ->whereBetween('orders.created_at', $dateRange)
            ->selectRaw('
                products.id,
                products.name,
                SUM(order_items.quantity) as total_sold,
                SUM(order_items.subtotal) as revenue,
                AVG(order_items.price) as average_price
            ')
            ->groupBy('products.id', 'products.name')
            ->orderByDesc('total_sold')
            ->limit(20)
            ->get();
    }

    protected function getDateRange($period)
    {
        switch ($period) {
            case 'today':
                return [now()->startOfDay(), now()->endOfDay()];
            case 'yesterday':
                return [now()->subDay()->startOfDay(), now()->subDay()->endOfDay()];
            case 'last_7_days':
                return [now()->subDays(7), now()];
            case 'last_30_days':
                return [now()->subDays(30), now()];
            case 'this_month':
                return [now()->startOfMonth(), now()->endOfMonth()];
            case 'last_month':
                return [now()->subMonth()->startOfMonth(), now()->subMonth()->endOfMonth()];
            default:
                return [now()->subDays(30), now()];
        }
    }

    // Additional analytics methods would be implemented here
    // This includes all the methods referenced above for different analytics types

    /**
     * Clear analytics cache
     */
    public function clearCache($type = null, $id = null)
    {
        if ($type && $id) {
            Cache::forget($this->cachePrefix . "{$type}:{$id}:*");
        } elseif ($type) {
            Cache::forget($this->cachePrefix . "{$type}:*");
        } else {
            Cache::flush(); // Clear all cache - use with caution
        }
    }

    /**
     * Generate analytics report
     */
    public function generateReport($type, $params = [])
    {
        try {
            $reportData = [];
            
            switch ($type) {
                case 'seller_monthly':
                    $reportData = $this->generateSellerMonthlyReport($params);
                    break;
                case 'platform_weekly':
                    $reportData = $this->generatePlatformWeeklyReport($params);
                    break;
                case 'delivery_daily':
                    $reportData = $this->generateDeliveryDailyReport($params);
                    break;
                default:
                    throw new \Exception("Unknown report type: {$type}");
            }
            
            // Store report for future access
            $reportId = uniqid('report_');
            Redis::setex("report:{$reportId}", 86400 * 7, json_encode($reportData)); // 7 days
            
            return [
                'report_id' => $reportId,
                'data' => $reportData,
                'generated_at' => now()->toISOString(),
            ];

        } catch (\Exception $e) {
            Log::error('Failed to generate analytics report: ' . $e->getMessage());
            return null;
        }
    }

    // Report generation methods would be implemented here
}