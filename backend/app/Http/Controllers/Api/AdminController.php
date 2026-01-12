<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\User;
use App\Models\Vendor;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;
use Carbon\Carbon;

class AdminController extends Controller
{
    /**
     * Get admin dashboard data
     */
    public function dashboard(): JsonResponse
    {
        $stats = [
            'total_users' => User::count(),
            'total_vendors' => Vendor::count(),
            'pending_vendors' => Vendor::where('status', 'pending')->count(),
            'total_orders' => Order::count(),
            'total_products' => Product::count(),
            'today_orders' => Order::whereDate('created_at', today())->count(),
            'monthly_revenue' => Order::whereMonth('created_at', now()->month)
                                    ->whereYear('created_at', now()->year)
                                    ->sum('total_amount'),
            'pending_orders' => Order::where('status', 'pending')->count(),
        ];

        $recent_orders = Order::with(['user', 'vendor'])
                              ->latest()
                              ->limit(10)
                              ->get();

        $monthly_sales = $this->getMonthlySales();

        return response()->json([
            'stats' => $stats,
            'recent_orders' => $recent_orders,
            'monthly_sales' => $monthly_sales,
        ]);
    }

    /**
     * Get analytics data
     */
    public function analytics(): JsonResponse
    {
        $data = [
            'revenue_chart' => $this->getRevenueChart(),
            'top_products' => $this->getTopProducts(),
            'top_vendors' => $this->getTopVendors(),
            'customer_growth' => $this->getCustomerGrowth(),
        ];

        return response()->json($data);
    }

    /**
     * Get monthly sales data for charts
     */
    private function getMonthlySales(): array
    {
        $months = [];
        for ($i = 11; $i >= 0; $i--) {
            $date = Carbon::now()->subMonths($i);
            $months[] = [
                'month' => $date->format('M Y'),
                'sales' => Order::whereYear('created_at', $date->year)
                               ->whereMonth('created_at', $date->month)
                               ->sum('total_amount')
            ];
        }
        return $months;
    }

    /**
     * Get revenue chart data
     */
    private function getRevenueChart(): array
    {
        $days = [];
        for ($i = 29; $i >= 0; $i--) {
            $date = Carbon::now()->subDays($i);
            $days[] = [
                'date' => $date->format('M j'),
                'revenue' => Order::whereDate('created_at', $date)->sum('total_amount')
            ];
        }
        return $days;
    }

    /**
     * Get top selling products
     */
    private function getTopProducts(): array
    {
        return [];
    }

    /**
     * Get top performing vendors
     */
    private function getTopVendors(): array
    {
        return Vendor::limit(10)
                     ->get()
                     ->map(function ($vendor) {
                         return [
                             'name' => $vendor->business_name,
                             'revenue' => 0
                         ];
                     })
                     ->toArray();
    }

    /**
     * Get customer growth data
     */
    private function getCustomerGrowth(): array
    {
        $months = [];
        for ($i = 11; $i >= 0; $i--) {
            $date = Carbon::now()->subMonths($i);
            $months[] = [
                'month' => $date->format('M Y'),
                'customers' => User::whereYear('created_at', $date->year)
                                  ->whereMonth('created_at', $date->month)
                                  ->count()
            ];
        }
        return $months;
    }

    /**
     * Admin: List categories
     */
    public function getCategories(Request $request): JsonResponse
    {
        $query = Category::query();
        if ($request->boolean('active_only', false)) {
            $query->where('is_active', true);
        }
        $categories = $query->orderBy('sort_order')->get();
        return response()->json(['status' => 'success', 'data' => $categories]);
    }

    /**
     * Admin: Create category
     */
    public function createCategory(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => 'nullable|string|max:255|unique:categories,slug',
            'description' => 'nullable|string',
            'parent_id' => 'nullable|exists:categories,id',
            'is_active' => 'sometimes|boolean',
            'sort_order' => 'sometimes|integer',
        ]);
        if (empty($data['slug'])) {
            $data['slug'] = \Illuminate\Support\Str::slug($data['name']);
        }
        $category = Category::create(array_merge([
            'is_active' => true,
            'sort_order' => 0,
        ], $data));
        return response()->json(['status' => 'success', 'data' => $category], 201);
    }

    /**
     * Admin: Update category
     */
    public function updateCategory($id, Request $request): JsonResponse
    {
        $category = Category::findOrFail($id);
        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'slug' => 'sometimes|string|max:255|unique:categories,slug,' . $category->id,
            'description' => 'nullable|string',
            'parent_id' => 'nullable|exists:categories,id',
            'is_active' => 'sometimes|boolean',
            'sort_order' => 'sometimes|integer',
        ]);
        $category->update($data);
        return response()->json(['status' => 'success', 'data' => $category]);
    }

    /**
     * Admin: Delete category
     */
    public function deleteCategory($id): JsonResponse
    {
        $category = Category::findOrFail($id);
        $category->delete();
        return response()->json(['status' => 'success']);
    }
}
