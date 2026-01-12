<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vendor;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class VendorController extends Controller
{
    /**
     * Get public vendor list
     */
    public function publicIndex(Request $request): JsonResponse
    {
        $vendors = Vendor::with('user')
                         ->where('status', 'approved')
                         ->when($request->search, function ($query, $search) {
                             $query->where('business_name', 'like', "%{$search}%")
                                   ->orWhere('business_description', 'like', "%{$search}%");
                         })
                         ->when($request->city, function ($query, $city) {
                             $query->where('city', $city);
                         })
                         ->paginate(20);

        return response()->json($vendors);
    }

    /**
     * Get vendor dashboard data
     */
    public function dashboard(Request $request): JsonResponse
    {
        $vendor = $request->user()->vendor;
        
        if (!$vendor) {
            return response()->json(['message' => 'Vendor not found'], 404);
        }

        $stats = [
            'total_products' => Product::where('vendor_id', $vendor->id)->count(),
            'active_products' => Product::where('vendor_id', $vendor->id)
                                       ->where('status', 'approved')->count(),
            'total_orders' => Order::where('vendor_id', $vendor->id)->count(),
            'pending_orders' => Order::where('vendor_id', $vendor->id)
                                    ->where('status', 'pending')->count(),
            'today_orders' => Order::where('vendor_id', $vendor->id)
                                   ->whereDate('created_at', today())->count(),
            'monthly_revenue' => Order::where('vendor_id', $vendor->id)
                                     ->where('payment_status', 'paid')
                                     ->whereMonth('created_at', now()->month)
                                     ->whereYear('created_at', now()->year)
                                     ->sum('total_amount'),
            'commission_rate' => $vendor->commission_rate,
        ];

        $recentOrders = Order::where('vendor_id', $vendor->id)
                            ->with(['user', 'orderItems.product'])
                            ->latest()
                            ->limit(10)
                            ->get();

        $salesChart = $this->getVendorSalesChart($vendor);
        $topProducts = $this->getTopProducts($vendor);

        return response()->json([
            'stats' => $stats,
            'recent_orders' => $recentOrders,
            'sales_chart' => $salesChart,
            'top_products' => $topProducts,
        ]);
    }

    /**
     * Get vendor analytics
     */
    public function analytics(Request $request): JsonResponse
    {
        $vendor = $request->user()->vendor;
        
        if (!$vendor) {
            return response()->json(['message' => 'Vendor not found'], 404);
        }

        $period = $request->period ?? '30days';

        $analytics = [
            'revenue_analytics' => $this->getRevenueAnalytics($vendor, $period),
            'product_analytics' => $this->getProductAnalytics($vendor, $period),
            'order_analytics' => $this->getOrderAnalytics($vendor, $period),
            'customer_analytics' => $this->getCustomerAnalytics($vendor, $period),
        ];

        return response()->json($analytics);
    }

    /**
     * Get vendor commission details
     */
    public function commission(Request $request): JsonResponse
    {
        $vendor = $request->user()->vendor;
        
        if (!$vendor) {
            return response()->json(['message' => 'Vendor not found'], 404);
        }

        $startDate = $request->start_date ? Carbon::parse($request->start_date) : now()->startOfMonth();
        $endDate = $request->end_date ? Carbon::parse($request->end_date) : now()->endOfMonth();

        $orders = Order::where('vendor_id', $vendor->id)
                       ->where('payment_status', 'paid')
                       ->whereBetween('created_at', [$startDate, $endDate])
                       ->get();

        $totalSales = $orders->sum('total_amount');
        $totalCommission = $orders->sum(function ($order) use ($vendor) {
            return $vendor->calculateCommission($order->total_amount);
        });
        $netEarnings = $totalSales - $totalCommission;

        $commissionBreakdown = $orders->map(function ($order) use ($vendor) {
            return [
                'order_number' => $order->order_number,
                'order_date' => $order->created_at,
                'order_amount' => $order->total_amount,
                'commission_rate' => $vendor->commission_rate,
                'commission_amount' => $vendor->calculateCommission($order->total_amount),
                'net_amount' => $order->total_amount - $vendor->calculateCommission($order->total_amount),
            ];
        });

        return response()->json([
            'period' => [
                'start_date' => $startDate->format('Y-m-d'),
                'end_date' => $endDate->format('Y-m-d'),
            ],
            'summary' => [
                'total_orders' => $orders->count(),
                'total_sales' => $totalSales,
                'commission_rate' => $vendor->commission_rate,
                'total_commission' => $totalCommission,
                'net_earnings' => $netEarnings,
            ],
            'breakdown' => $commissionBreakdown,
        ]);
    }

    /**
     * Update vendor profile
     */
    public function update(Request $request): JsonResponse
    {
        $vendor = $request->user()->vendor;
        
        if (!$vendor) {
            return response()->json(['message' => 'Vendor not found'], 404);
        }

        $request->validate([
            'business_name' => 'sometimes|string|max:255',
            'business_description' => 'sometimes|string',
            'business_phone' => 'sometimes|string|max:20',
            'business_address' => 'sometimes|string',
            'city' => 'sometimes|string|max:100',
            'state' => 'sometimes|string|max:100',
            'postal_code' => 'sometimes|string|max:20',
            'website' => 'sometimes|url',
            'logo' => 'sometimes|image|mimes:jpeg,png,jpg|max:2048',
            'banner' => 'sometimes|image|mimes:jpeg,png,jpg|max:5120',
        ]);

        $data = $request->only([
            'business_name', 'business_description', 'business_phone',
            'business_address', 'city', 'state', 'postal_code', 'website'
        ]);

        if ($request->hasFile('logo')) {
            $data['logo'] = $request->file('logo')->store('vendor_logos', 'public');
        }

        if ($request->hasFile('banner')) {
            $data['banner'] = $request->file('banner')->store('vendor_banners', 'public');
        }

        $vendor->update($data);

        return response()->json([
            'message' => 'Vendor profile updated successfully',
            'vendor' => $vendor->fresh()
        ]);
    }

    /**
     * Apply to become a vendor
     */
    public function apply(Request $request): JsonResponse
    {
        $user = $request->user();
        
        if ($user->vendor) {
            return response()->json(['message' => 'User is already a vendor'], 400);
        }

        $request->validate([
            'business_name' => 'required|string|max:255',
            'business_email' => 'required|email|unique:vendors,business_email',
            'business_phone' => 'required|string|max:20',
            'business_description' => 'required|string',
            'business_address' => 'required|string',
            'city' => 'required|string|max:100',
            'state' => 'required|string|max:100',
            'postal_code' => 'required|string|max:20',
            'country' => 'required|string|max:100',
            'tax_id' => 'nullable|string|max:50',
            'business_documents' => 'required|array',
            'business_documents.*' => 'file|mimes:pdf,jpg,jpeg,png|max:5120',
        ]);

        $documents = [];
        if ($request->hasFile('business_documents')) {
            foreach ($request->file('business_documents') as $file) {
                $documents[] = $file->store('vendor_documents', 'public');
            }
        }

        $vendor = Vendor::create([
            'user_id' => $user->id,
            'business_name' => $request->business_name,
            'business_email' => $request->business_email,
            'business_phone' => $request->business_phone,
            'business_description' => $request->business_description,
            'business_address' => $request->business_address,
            'city' => $request->city,
            'state' => $request->state,
            'postal_code' => $request->postal_code,
            'country' => $request->country,
            'tax_id' => $request->tax_id,
            'business_documents' => $documents,
            'status' => 'pending',
        ]);

        return response()->json([
            'message' => 'Vendor application submitted successfully',
            'vendor' => $vendor
        ], 201);
    }

    // Private helper methods

    private function getVendorSalesChart(Vendor $vendor): array
    {
        $days = [];
        for ($i = 29; $i >= 0; $i--) {
            $date = Carbon::now()->subDays($i);
            $sales = Order::where('vendor_id', $vendor->id)
                         ->where('payment_status', 'paid')
                         ->whereDate('created_at', $date)
                         ->sum('total_amount');
            
            $days[] = [
                'date' => $date->format('M j'),
                'sales' => $sales
            ];
        }
        return $days;
    }

    private function getTopProducts(Vendor $vendor): array
    {
        return Product::where('vendor_id', $vendor->id)
                     ->withCount(['orderItems as total_sold' => function ($query) {
                         $query->select(DB::raw('SUM(quantity)'));
                     }])
                     ->orderBy('total_sold', 'desc')
                     ->limit(10)
                     ->get()
                     ->toArray();
    }

    private function getRevenueAnalytics(Vendor $vendor, string $period): array
    {
        $startDate = match($period) {
            '7days' => now()->subDays(7),
            '30days' => now()->subDays(30),
            '90days' => now()->subDays(90),
            '1year' => now()->subYear(),
            default => now()->subDays(30)
        };

        $revenue = Order::where('vendor_id', $vendor->id)
                       ->where('payment_status', 'paid')
                       ->where('created_at', '>=', $startDate)
                       ->sum('total_amount');

        $previousRevenue = Order::where('vendor_id', $vendor->id)
                                ->where('payment_status', 'paid')
                                ->whereBetween('created_at', [
                                    $startDate->copy()->subDays($startDate->diffInDays(now())),
                                    $startDate
                                ])
                                ->sum('total_amount');

        $growth = $previousRevenue > 0 ? (($revenue - $previousRevenue) / $previousRevenue) * 100 : 0;

        return [
            'current_revenue' => $revenue,
            'previous_revenue' => $previousRevenue,
            'growth_percentage' => round($growth, 2),
        ];
    }

    private function getProductAnalytics(Vendor $vendor, string $period): array
    {
        return [
            'total_products' => Product::where('vendor_id', $vendor->id)->count(),
            'active_products' => Product::where('vendor_id', $vendor->id)
                                       ->where('status', 'approved')->count(),
            'out_of_stock' => Product::where('vendor_id', $vendor->id)
                                    ->where('stock_status', 'out_of_stock')->count(),
        ];
    }

    private function getOrderAnalytics(Vendor $vendor, string $period): array
    {
        $startDate = match($period) {
            '7days' => now()->subDays(7),
            '30days' => now()->subDays(30),
            '90days' => now()->subDays(90),
            '1year' => now()->subYear(),
            default => now()->subDays(30)
        };

        return [
            'total_orders' => Order::where('vendor_id', $vendor->id)
                                   ->where('created_at', '>=', $startDate)->count(),
            'pending_orders' => Order::where('vendor_id', $vendor->id)
                                     ->where('status', 'pending')->count(),
            'completed_orders' => Order::where('vendor_id', $vendor->id)
                                       ->where('status', 'delivered')
                                       ->where('created_at', '>=', $startDate)->count(),
        ];
    }

    private function getCustomerAnalytics(Vendor $vendor, string $period): array
    {
        $uniqueCustomers = Order::where('vendor_id', $vendor->id)
                                ->distinct('user_id')
                                ->count('user_id');

        $repeatCustomers = Order::where('vendor_id', $vendor->id)
                                ->select('user_id', DB::raw('COUNT(*) as order_count'))
                                ->groupBy('user_id')
                                ->having('order_count', '>', 1)
                                ->count();

        return [
            'total_customers' => $uniqueCustomers,
            'repeat_customers' => $repeatCustomers,
            'repeat_rate' => $uniqueCustomers > 0 ? round(($repeatCustomers / $uniqueCustomers) * 100, 2) : 0,
        ];
    }
}
