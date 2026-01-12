<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\WishlistItem;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class WishlistController extends Controller
{
    /**
     * Get user's wishlist
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = min($request->get('per_page', 20), 100);
        
        $wishlist = WishlistItem::with(['product.images', 'product.vendor'])
            ->where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $wishlist
        ]);
    }

    /**
     * Add product to wishlist
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'product_id' => 'required|exists:products,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $userId = $request->user()->id;
        $productId = $request->product_id;

        // Check if product exists and is active
        $product = Product::where('id', $productId)
            ->where('status', 'active')
            ->first();

        if (!$product) {
            return response()->json([
                'status' => 'error',
                'message' => 'Product not found or inactive'
            ], 404);
        }

        // Check if already in wishlist
        $existingItem = WishlistItem::where('user_id', $userId)
            ->where('product_id', $productId)
            ->first();

        if ($existingItem) {
            return response()->json([
                'status' => 'error',
                'message' => 'Product already in wishlist'
            ], 409);
        }

        $wishlistItem = WishlistItem::create([
            'user_id' => $userId,
            'product_id' => $productId,
        ]);

        $wishlistItem->load('product.images');

        return response()->json([
            'status' => 'success',
            'message' => 'Product added to wishlist',
            'data' => $wishlistItem
        ], 201);
    }

    /**
     * Remove product from wishlist
     */
    public function destroy(Request $request, $productId): JsonResponse
    {
        $wishlistItem = WishlistItem::where('user_id', $request->user()->id)
            ->where('product_id', $productId)
            ->first();

        if (!$wishlistItem) {
            return response()->json([
                'status' => 'error',
                'message' => 'Product not in wishlist'
            ], 404);
        }

        $wishlistItem->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Product removed from wishlist'
        ]);
    }

    /**
     * Check if product is in user's wishlist
     */
    public function check(Request $request, $productId): JsonResponse
    {
        $inWishlist = WishlistItem::where('user_id', $request->user()->id)
            ->where('product_id', $productId)
            ->exists();

        return response()->json([
            'status' => 'success',
            'data' => [
                'in_wishlist' => $inWishlist
            ]
        ]);
    }

    /**
     * Clear all items from wishlist
     */
    public function clear(Request $request): JsonResponse
    {
        $deletedCount = WishlistItem::where('user_id', $request->user()->id)->delete();

        return response()->json([
            'status' => 'success',
            'message' => "Removed {$deletedCount} items from wishlist"
        ]);
    }
}