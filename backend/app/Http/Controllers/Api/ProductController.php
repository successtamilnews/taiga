<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;

class ProductController extends Controller
{
    /**
     * Get all products with filtering
     */
    public function index(Request $request): JsonResponse
    {
        $query = Product::with(['vendor', 'category'])
                        ->approved()
                        ->inStock();

        // Apply filters
        if ($request->category_id) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->vendor_id) {
            $query->where('vendor_id', $request->vendor_id);
        }

        if ($request->featured) {
            $query->featured();
        }

        if ($request->type) {
            $query->where('type', $request->type);
        }

        if ($request->min_price) {
            $query->where('price', '>=', $request->min_price);
        }

        if ($request->max_price) {
            $query->where('price', '<=', $request->max_price);
        }

        if ($request->search) {
            $query->where('name', 'like', "%{$request->search}%")
                  ->orWhere('description', 'like', "%{$request->search}%");
        }

        // Apply sorting
        $sortBy = $request->sort_by ?? 'created_at';
        $sortOrder = $request->sort_order ?? 'desc';
        $query->orderBy($sortBy, $sortOrder);

        $products = $query->paginate($request->per_page ?? 15);

        return response()->json($products);
    }

    /**
     * Get single product
     */
    public function show(Product $product): JsonResponse
    {
        $product->load(['vendor', 'category']);

        return response()->json([
            'product' => $product
        ]);
    }

    /**
     * Create new product (vendors only)
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'category_id' => 'required|exists:categories,id',
            'description' => 'required|string',
            'short_description' => 'nullable|string',
            'sku' => 'required|string|unique:products,sku',
            'price' => 'required|numeric|min:0',
            'sale_price' => 'nullable|numeric|min:0|lt:price',
            'stock_quantity' => 'required|integer|min:0',
            'weight' => 'nullable|numeric|min:0',
            'type' => 'required|in:physical,digital',
            'images' => 'nullable|array',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif|max:2048',
            'digital_file' => 'nullable|file|max:10240', // 10MB max
        ]);

        $vendor = $request->user()->vendor;
        
        if (!$vendor || !$vendor->isApproved()) {
            return response()->json([
                'message' => 'Vendor account not approved'
            ], 403);
        }

        $data = $request->all();
        $data['vendor_id'] = $vendor->id;
        $data['slug'] = Str::slug($request->name);
        $data['status'] = 'pending'; // Requires admin approval

        // Handle images upload
        if ($request->hasFile('images')) {
            $images = [];
            foreach ($request->file('images') as $image) {
                $path = $image->store('products', 'public');
                $images[] = $path;
            }
            $data['images'] = $images;
        }

        // Handle digital file upload
        if ($request->hasFile('digital_file')) {
            $data['digital_file'] = $request->file('digital_file')->store('digital_products', 'public');
        }

        $product = Product::create($data);

        return response()->json([
            'message' => 'Product created successfully',
            'product' => $product->load(['vendor', 'category'])
        ], 201);
    }

    /**
     * Update product
     */
    public function update(Request $request, Product $product): JsonResponse
    {
        $vendor = $request->user()->vendor;
        
        if (!$vendor || $product->vendor_id !== $vendor->id) {
            return response()->json([
                'message' => 'Unauthorized'
            ], 403);
        }

        $request->validate([
            'name' => 'sometimes|string|max:255',
            'category_id' => 'sometimes|exists:categories,id',
            'description' => 'sometimes|string',
            'short_description' => 'sometimes|string',
            'price' => 'sometimes|numeric|min:0',
            'sale_price' => 'sometimes|nullable|numeric|min:0',
            'stock_quantity' => 'sometimes|integer|min:0',
            'weight' => 'sometimes|nullable|numeric|min:0',
            'type' => 'sometimes|in:physical,digital',
        ]);

        $data = $request->all();
        
        if ($request->has('name')) {
            $data['slug'] = Str::slug($request->name);
        }

        $product->update($data);

        return response()->json([
            'message' => 'Product updated successfully',
            'product' => $product->load(['vendor', 'category'])
        ]);
    }

    /**
     * Delete product
     */
    public function destroy(Product $product): JsonResponse
    {
        $vendor = request()->user()->vendor;
        
        if (!$vendor || $product->vendor_id !== $vendor->id) {
            return response()->json([
                'message' => 'Unauthorized'
            ], 403);
        }

        $product->delete();

        return response()->json([
            'message' => 'Product deleted successfully'
        ]);
    }

    /**
     * Get all categories
     */
    public function categories(): JsonResponse
    {
        $categories = Category::active()
                             ->with('children')
                             ->parents()
                             ->orderBy('sort_order')
                             ->get();

        return response()->json([
            'categories' => $categories
        ]);
    }
}
