<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Coupon;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    /**
     * Create a new order
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.variation' => 'nullable|array',
            'billing_address' => 'required|array',
            'shipping_address' => 'required|array',
            'coupon_code' => 'nullable|string|exists:coupons,code',
            'notes' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($request) {
            $user = $request->user();
            $subtotal = 0;
            $orderItems = [];

            // Validate items and calculate subtotal
            foreach ($request->items as $item) {
                $product = Product::find($item['product_id']);
                
                if (!$product->isInStock()) {
                    return response()->json([
                        'message' => "Product {$product->name} is out of stock"
                    ], 400);
                }

                if ($product->manage_stock && $product->stock_quantity < $item['quantity']) {
                    return response()->json([
                        'message' => "Insufficient stock for {$product->name}"
                    ], 400);
                }

                $price = $product->getEffectivePrice();
                $total = $price * $item['quantity'];
                $subtotal += $total;

                $orderItems[] = [
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'product_sku' => $product->sku,
                    'product_variation' => $item['variation'] ?? null,
                    'quantity' => $item['quantity'],
                    'price' => $price,
                    'total' => $total,
                ];
            }

            // Apply coupon if provided
            $discountAmount = 0;
            $couponCode = null;
            
            if ($request->coupon_code) {
                $coupon = Coupon::where('code', $request->coupon_code)->first();
                if ($coupon && $coupon->isValid()) {
                    $discountAmount = $coupon->calculateDiscount($subtotal);
                    $couponCode = $coupon->code;
                    $coupon->increment('used_count');
                }
            }

            // Calculate totals
            $taxAmount = $subtotal * 0.1; // 10% tax
            $shippingAmount = $this->calculateShipping($request->shipping_address, $orderItems);
            $totalAmount = $subtotal + $taxAmount + $shippingAmount - $discountAmount;

            // Group items by vendor to create separate orders
            $vendorGroups = collect($orderItems)->groupBy(function ($item) {
                return Product::find($item['product_id'])->vendor_id;
            });

            $orders = [];

            foreach ($vendorGroups as $vendorId => $items) {
                $vendorSubtotal = $items->sum('total');
                $vendorTax = $vendorSubtotal * 0.1;
                $vendorDiscount = $discountAmount > 0 ? ($discountAmount * ($vendorSubtotal / $subtotal)) : 0;
                $vendorTotal = $vendorSubtotal + $vendorTax + $shippingAmount - $vendorDiscount;

                $order = Order::create([
                    'order_number' => 'ORD-' . strtoupper(Str::random(8)),
                    'user_id' => $user->id,
                    'vendor_id' => $vendorId,
                    'subtotal' => $vendorSubtotal,
                    'tax_amount' => $vendorTax,
                    'shipping_amount' => $shippingAmount,
                    'discount_amount' => $vendorDiscount,
                    'total_amount' => $vendorTotal,
                    'currency' => config('app.currency', 'USD'),
                    'billing_address' => $request->billing_address,
                    'shipping_address' => $request->shipping_address,
                    'coupon_code' => $couponCode,
                    'notes' => $request->notes,
                ]);

                // Create order items
                foreach ($items as $item) {
                    OrderItem::create(array_merge($item, ['order_id' => $order->id]));
                    
                    // Update product stock
                    $product = Product::find($item['product_id']);
                    if ($product->manage_stock) {
                        $product->decrement('stock_quantity', $item['quantity']);
                    }
                }

                $orders[] = $order->load(['orderItems', 'vendor']);
            }

            return response()->json([
                'message' => 'Orders created successfully',
                'orders' => $orders,
                'total_amount' => $totalAmount,
            ], 201);
        });
    }

    /**
     * Get user's orders
     */
    public function userOrders(Request $request): JsonResponse
    {
        $orders = $request->user()
                          ->orders()
                          ->with(['vendor', 'orderItems.product'])
                          ->latest()
                          ->paginate(20);

        return response()->json($orders);
    }

    /**
     * Get single order
     */
    public function show(Order $order): JsonResponse
    {
        // Check if user owns the order or is admin/vendor
        $user = request()->user();
        if ($order->user_id !== $user->id && !$user->isAdmin() && 
            (!$user->isVendor() || $order->vendor_id !== $user->vendor->id)) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $order->load(['vendor', 'orderItems.product', 'user']);

        return response()->json(['order' => $order]);
    }

    /**
     * Cancel order
     */
    public function cancel(Request $request, Order $order): JsonResponse
    {
        $user = $request->user();
        
        if ($order->user_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if (!$order->canBeCancelled()) {
            return response()->json([
                'message' => 'Order cannot be cancelled at this stage'
            ], 400);
        }

        return DB::transaction(function () use ($order) {
            $order->update(['status' => 'cancelled']);

            // Restore product stock
            foreach ($order->orderItems as $item) {
                $product = Product::find($item->product_id);
                if ($product && $product->manage_stock) {
                    $product->increment('stock_quantity', $item->quantity);
                }
            }

            // Refund wallet payment if applicable
            if ($order->payment_method === 'wallet' && $order->payment_status === 'paid') {
                $order->user->wallet->addBalance($order->total_amount);
                $order->update(['payment_status' => 'refunded']);
            }

            return response()->json([
                'message' => 'Order cancelled successfully',
                'order' => $order->fresh()
            ]);
        });
    }

    /**
     * Get vendor's orders
     */
    public function vendorOrders(Request $request): JsonResponse
    {
        $vendor = $request->user()->vendor;
        
        if (!$vendor) {
            return response()->json(['message' => 'Vendor not found'], 404);
        }

        $orders = Order::where('vendor_id', $vendor->id)
                       ->with(['user', 'orderItems.product'])
                       ->when($request->status, function ($query, $status) {
                           $query->where('status', $status);
                       })
                       ->latest()
                       ->paginate(20);

        return response()->json($orders);
    }

    /**
     * Update order status (vendors only)
     */
    public function updateStatus(Request $request, Order $order): JsonResponse
    {
        $vendor = $request->user()->vendor;
        
        if (!$vendor || $order->vendor_id !== $vendor->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'status' => 'required|in:processing,shipped,delivered',
            'tracking_info' => 'nullable|array',
        ]);

        $updateData = ['status' => $request->status];

        if ($request->status === 'shipped') {
            $updateData['shipped_at'] = now();
            if ($request->tracking_info) {
                $updateData['tracking_info'] = $request->tracking_info;
            }
        }

        if ($request->status === 'delivered') {
            $updateData['delivered_at'] = now();
        }

        $order->update($updateData);

        return response()->json([
            'message' => 'Order status updated successfully',
            'order' => $order->fresh()
        ]);
    }

    /**
     * Get delivery orders
     */
    public function deliveryOrders(Request $request): JsonResponse
    {
        $deliveryPerson = $request->user()->deliveryPerson;
        
        if (!$deliveryPerson) {
            return response()->json(['message' => 'Delivery person not found'], 404);
        }

        // For now, get all shipped orders in delivery person's working areas
        $orders = Order::where('status', 'shipped')
                       ->with(['user', 'vendor', 'orderItems.product'])
                       ->latest()
                       ->paginate(20);

        return response()->json($orders);
    }

    /**
     * Mark order as picked up
     */
    public function markPickedUp(Request $request, Order $order): JsonResponse
    {
        $deliveryPerson = $request->user()->deliveryPerson;
        
        if (!$deliveryPerson) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $order->update([
            'status' => 'out_for_delivery',
            'tracking_info' => array_merge($order->tracking_info ?? [], [
                'picked_up_at' => now(),
                'delivery_person_id' => $deliveryPerson->id,
            ])
        ]);

        $deliveryPerson->markBusy();

        return response()->json([
            'message' => 'Order marked as picked up',
            'order' => $order->fresh()
        ]);
    }

    /**
     * Mark order as delivered
     */
    public function markDelivered(Request $request, Order $order): JsonResponse
    {
        $deliveryPerson = $request->user()->deliveryPerson;
        
        if (!$deliveryPerson) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'delivery_proof' => 'nullable|image|max:2048',
            'notes' => 'nullable|string',
        ]);

        $trackingInfo = array_merge($order->tracking_info ?? [], [
            'delivered_at' => now(),
            'delivery_person_id' => $deliveryPerson->id,
            'delivery_notes' => $request->notes,
        ]);

        if ($request->hasFile('delivery_proof')) {
            $trackingInfo['delivery_proof'] = $request->file('delivery_proof')
                                                    ->store('delivery_proofs', 'public');
        }

        $order->update([
            'status' => 'delivered',
            'delivered_at' => now(),
            'tracking_info' => $trackingInfo,
        ]);

        $deliveryPerson->markAvailable();
        $deliveryPerson->increment('total_deliveries');

        return response()->json([
            'message' => 'Order marked as delivered',
            'order' => $order->fresh()
        ]);
    }

    /**
     * Update delivery location
     */
    public function updateLocation(Request $request, Order $order): JsonResponse
    {
        $deliveryPerson = $request->user()->deliveryPerson;
        
        if (!$deliveryPerson) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        $deliveryPerson->updateLocation($request->latitude, $request->longitude);

        $trackingInfo = array_merge($order->tracking_info ?? [], [
            'current_location' => [
                'latitude' => $request->latitude,
                'longitude' => $request->longitude,
                'updated_at' => now(),
            ]
        ]);

        $order->update(['tracking_info' => $trackingInfo]);

        return response()->json([
            'message' => 'Location updated successfully'
        ]);
    }

    /**
     * Calculate shipping cost based on address and items
     */
    private function calculateShipping(array $address, array $items): float
    {
        // Simple shipping calculation - in production, integrate with shipping APIs
        $baseShipping = 5.00;
        $itemCount = collect($items)->sum('quantity');
        
        return $baseShipping + ($itemCount * 0.50);
    }
}
