<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Coupon;
use App\Models\ShippingAddress;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class OrderController extends Controller
{
    /**
     * Get user orders
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = min($request->get('per_page', 20), 100);
        
        $orders = Order::with(['items.product', 'payment', 'vendor'])
            ->where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $orders
        ]);
    }

    /**
     * Show specific order
     */
    public function show(Request $request, $id): JsonResponse
    {
        $order = Order::with(['items.product.images', 'payment', 'vendor', 'deliveryPerson'])
            ->where('user_id', $request->user()->id)
            ->find($id);

        if (!$order) {
            return response()->json([
                'status' => 'error',
                'message' => 'Order not found'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $order
        ]);
    }

    /**
     * Create new order
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'shipping_address_id' => 'required|exists:shipping_addresses,id',
            'payment_method' => 'required|string|in:card,google_pay,apple_pay,sampath_ipg,cod',
            'coupon_code' => 'sometimes|string|exists:coupons,code',
            'notes' => 'sometimes|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        // Verify shipping address belongs to user
        $shippingAddress = ShippingAddress::where('id', $request->shipping_address_id)
            ->where('user_id', $request->user()->id)
            ->first();

        if (!$shippingAddress) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid shipping address'
            ], 400);
        }

        try {
            DB::beginTransaction();

            $user = $request->user();
            $totalAmount = 0;
            $items = [];

            // Validate products and calculate total
            foreach ($request->items as $itemData) {
                $product = Product::where('id', $itemData['product_id'])
                    ->where('status', 'active')
                    ->where('stock_quantity', '>=', $itemData['quantity'])
                    ->first();

                if (!$product) {
                    throw new \Exception("Product ID {$itemData['product_id']} is not available or out of stock");
                }

                $itemTotal = $product->price * $itemData['quantity'];
                $totalAmount += $itemTotal;

                $items[] = [
                    'product' => $product,
                    'quantity' => $itemData['quantity'],
                    'price' => $product->price,
                    'total' => $itemTotal
                ];
            }

            // Apply coupon if provided
            $discount = 0;
            $coupon = null;
            if ($request->has('coupon_code')) {
                $coupon = Coupon::where('code', $request->coupon_code)
                    ->where('is_active', true)
                    ->where('start_date', '<=', now())
                    ->where('end_date', '>=', now())
                    ->where(function ($query) {
                        $query->whereNull('usage_limit')
                              ->orWhereRaw('used_count < usage_limit');
                    })
                    ->first();

                if ($coupon) {
                    if ($coupon->minimum_amount && $totalAmount < $coupon->minimum_amount) {
                        throw new \Exception("Minimum order amount for this coupon is {$coupon->minimum_amount}");
                    }

                    if ($coupon->type === 'percentage') {
                        $discount = ($totalAmount * $coupon->value) / 100;
                        if ($coupon->maximum_discount) {
                            $discount = min($discount, $coupon->maximum_discount);
                        }
                    } else {
                        $discount = min($coupon->value, $totalAmount);
                    }
                }
            }

            $finalAmount = $totalAmount - $discount;

            // Create order
            $order = Order::create([
                'user_id' => $user->id,
                'order_number' => $this->generateOrderNumber(),
                'status' => 'pending',
                'payment_status' => 'pending',
                'total_amount' => $totalAmount,
                'discount_amount' => $discount,
                'final_amount' => $finalAmount,
                'currency' => 'LKR',
                'payment_method' => $request->payment_method,
                'shipping_address' => json_encode($shippingAddress->toArray()),
                'notes' => $request->get('notes'),
                'coupon_code' => $coupon ? $coupon->code : null,
            ]);

            // Create order items and update stock
            foreach ($items as $item) {
                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $item['product']->id,
                    'vendor_id' => $item['product']->vendor_id,
                    'quantity' => $item['quantity'],
                    'price' => $item['price'],
                    'total_amount' => $item['total'],
                ]);

                // Update product stock
                $item['product']->decrement('stock_quantity', $item['quantity']);
            }

            // Update coupon usage
            if ($coupon) {
                $coupon->increment('used_count');
            }

            DB::commit();

            // Load order with relationships for response
            $order->load(['items.product', 'payment']);

            return response()->json([
                'status' => 'success',
                'message' => 'Order created successfully',
                'data' => $order
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage()
            ], 400);
        }
    }

    /**
     * Cancel order
     */
    public function cancel(Request $request, $id): JsonResponse
    {
        $order = Order::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->where('status', 'pending')
            ->first();

        if (!$order) {
            return response()->json([
                'status' => 'error',
                'message' => 'Order not found or cannot be cancelled'
            ], 404);
        }

        try {
            DB::beginTransaction();

            // Restore product stock
            foreach ($order->items as $item) {
                $item->product->increment('stock_quantity', $item->quantity);
            }

            // Update order status
            $order->update([
                'status' => 'cancelled',
                'cancelled_at' => now(),
                'cancel_reason' => $request->get('reason', 'Cancelled by customer')
            ]);

            DB::commit();

            return response()->json([
                'status' => 'success',
                'message' => 'Order cancelled successfully'
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to cancel order'
            ], 500);
        }
    }

    /**
     * Generate unique order number
     */
    private function generateOrderNumber(): string
    {
        do {
            $orderNumber = 'ORD-' . date('Ymd') . '-' . str_pad(mt_rand(1, 9999), 4, '0', STR_PAD_LEFT);
        } while (Order::where('order_number', $orderNumber)->exists());

        return $orderNumber;
    }
}