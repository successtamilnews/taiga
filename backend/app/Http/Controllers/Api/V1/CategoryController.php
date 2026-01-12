<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CategoryController extends Controller
{
    /**
     * Display a listing of categories
     */
    public function index(Request $request): JsonResponse
    {
        $query = Category::where('is_active', true);

        // Get only parent categories or include children
        if ($request->get('parent_only', false)) {
            $query->whereNull('parent_id');
        }

        // Include product count if requested
        if ($request->get('with_product_count', false)) {
            $query->withCount(['products' => function ($q) {
                $q->where('status', 'approved');
            }]);
        }

        $categories = $query->with('children')->orderBy('sort_order')->get();

        return response()->json([
            'status' => 'success',
            'data' => $categories
        ]);
    }

    /**
     * Display the specified category
     */
    public function show($id): JsonResponse
    {
        $category = Category::with(['children', 'parent'])
            ->withCount(['products' => function ($q) {
                $q->where('status', 'active');
            }])
            ->find($id);

        if (!$category) {
            return response()->json([
                'status' => 'error',
                'message' => 'Category not found'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $category
        ]);
    }

    /**
     * Get products by category
     */
    public function products($id, Request $request): JsonResponse
    {
        $category = Category::find($id);

        if (!$category) {
            return response()->json([
                'status' => 'error',
                'message' => 'Category not found'
            ], 404);
        }

        $query = $category->products()->with(['vendor', 'images'])
            ->where('status', 'approved');

        // Sort options
        $sortBy = $request->get('sort', 'created_at');
        $sortOrder = $request->get('order', 'desc');
        
        switch ($sortBy) {
            case 'price':
                $query->orderBy('price', $sortOrder);
                break;
            case 'name':
                $query->orderBy('name', $sortOrder);
                break;
            case 'rating':
                $query->withAvg('reviews', 'rating')->orderBy('reviews_avg_rating', $sortOrder);
                break;
            default:
                $query->orderBy('created_at', $sortOrder);
        }

        $perPage = min($request->get('per_page', 20), 100);
        $products = $query->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $products
        ]);
    }
}