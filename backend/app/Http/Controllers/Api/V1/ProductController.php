<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Category;
use App\Models\ProductImage;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class ProductController extends Controller
{
    /**
     * Display a listing of products
     */
    public function index(Request $request): JsonResponse
    {
        $query = Product::with(['category', 'vendor', 'images', 'attributes'])
            ->where('status', 'approved');

        // Filter by category
        if ($request->has('category')) {
            $query->where('category_id', $request->category);
        }

        // Filter by vendor
        if ($request->has('vendor')) {
            $query->where('vendor_id', $request->vendor);
        }

        // Search functionality
        if ($request->has('search')) {
            $searchTerm = $request->search;
            $query->where(function ($q) use ($searchTerm) {
                $q->where('name', 'like', "%{$searchTerm}%")
                  ->orWhere('description', 'like', "%{$searchTerm}%")
                  ->orWhere('short_description', 'like', "%{$searchTerm}%");
            });
        }

        // Price range filter
        if ($request->has('min_price')) {
            $query->where('price', '>=', $request->min_price);
        }
        if ($request->has('max_price')) {
            $query->where('price', '<=', $request->max_price);
        }

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

    /**
     * Display the specified product
     */
    public function show($id): JsonResponse
    {
        $product = Product::with([
            'category',
            'vendor',
            'images',
            'attributes',
            'reviews.user',
            'reviews' => function ($query) {
                $query->where('status', 'approved');
            }
        ])
        ->withAvg('reviews', 'rating')
        ->withCount('reviews')
        ->find($id);

        if (!$product) {
            return response()->json([
                'status' => 'error',
                'message' => 'Product not found'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $product
        ]);
    }

    /**
     * Get featured products
     */
    public function featured(Request $request): JsonResponse
    {
        $limit = min($request->get('limit', 10), 50);
        
        $products = Product::with(['category', 'vendor', 'images'])
            ->where('status', 'approved')
            ->where('is_featured', true)
            ->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $products
        ]);
    }

    /**
     * Get related products
     */
    public function related($id, Request $request): JsonResponse
    {
        $product = Product::find($id);
        
        if (!$product) {
            return response()->json([
                'status' => 'error',
                'message' => 'Product not found'
            ], 404);
        }

        $limit = min($request->get('limit', 10), 20);
        
        $relatedProducts = Product::with(['category', 'vendor', 'images'])
            ->where('category_id', $product->category_id)
            ->where('id', '!=', $id)
            ->where('status', 'approved')
            ->inRandomOrder()
            ->limit($limit)
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $relatedProducts
        ]);
    }

    /**
     * Get product reviews
     */
    public function reviews($id, Request $request): JsonResponse
    {
        $product = Product::find($id);
        
        if (!$product) {
            return response()->json([
                'status' => 'error',
                'message' => 'Product not found'
            ], 404);
        }

        $perPage = min($request->get('per_page', 10), 50);
        
        $reviews = $product->reviews()
            ->with('user')
            ->where('status', 'approved')
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $reviews
        ]);
    }
}