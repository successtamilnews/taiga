<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ShippingAddress;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class ShippingAddressController extends Controller
{
    /**
     * Get user's shipping addresses
     */
    public function index(Request $request): JsonResponse
    {
        $addresses = ShippingAddress::where('user_id', $request->user()->id)
            ->orderBy('is_default', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $addresses
        ]);
    }

    /**
     * Create new shipping address
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'full_name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'address_line_1' => 'required|string|max:255',
            'address_line_2' => 'nullable|string|max:255',
            'city' => 'required|string|max:100',
            'state' => 'required|string|max:100',
            'postal_code' => 'required|string|max:20',
            'country' => 'required|string|max:100',
            'is_default' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        // If this is set as default, remove default from other addresses
        if ($request->get('is_default', false)) {
            ShippingAddress::where('user_id', $request->user()->id)
                ->update(['is_default' => false]);
        }

        $address = ShippingAddress::create([
            'user_id' => $request->user()->id,
            'full_name' => $request->full_name,
            'phone' => $request->phone,
            'address_line_1' => $request->address_line_1,
            'address_line_2' => $request->address_line_2,
            'city' => $request->city,
            'state' => $request->state,
            'postal_code' => $request->postal_code,
            'country' => $request->country,
            'is_default' => $request->get('is_default', false),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Shipping address created successfully',
            'data' => $address
        ], 201);
    }

    /**
     * Update shipping address
     */
    public function update(Request $request, $id): JsonResponse
    {
        $address = ShippingAddress::where('user_id', $request->user()->id)
            ->find($id);

        if (!$address) {
            return response()->json([
                'status' => 'error',
                'message' => 'Shipping address not found'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'full_name' => 'sometimes|required|string|max:255',
            'phone' => 'sometimes|required|string|max:20',
            'address_line_1' => 'sometimes|required|string|max:255',
            'address_line_2' => 'nullable|string|max:255',
            'city' => 'sometimes|required|string|max:100',
            'state' => 'sometimes|required|string|max:100',
            'postal_code' => 'sometimes|required|string|max:20',
            'country' => 'sometimes|required|string|max:100',
            'is_default' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        // If this is set as default, remove default from other addresses
        if ($request->get('is_default', false)) {
            ShippingAddress::where('user_id', $request->user()->id)
                ->where('id', '!=', $id)
                ->update(['is_default' => false]);
        }

        $address->update($request->only([
            'full_name', 'phone', 'address_line_1', 'address_line_2',
            'city', 'state', 'postal_code', 'country', 'is_default'
        ]));

        return response()->json([
            'status' => 'success',
            'message' => 'Shipping address updated successfully',
            'data' => $address
        ]);
    }

    /**
     * Delete shipping address
     */
    public function destroy(Request $request, $id): JsonResponse
    {
        $address = ShippingAddress::where('user_id', $request->user()->id)
            ->find($id);

        if (!$address) {
            return response()->json([
                'status' => 'error',
                'message' => 'Shipping address not found'
            ], 404);
        }

        $address->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Shipping address deleted successfully'
        ]);
    }

    /**
     * Set address as default
     */
    public function setDefault(Request $request, $id): JsonResponse
    {
        $address = ShippingAddress::where('user_id', $request->user()->id)
            ->find($id);

        if (!$address) {
            return response()->json([
                'status' => 'error',
                'message' => 'Shipping address not found'
            ], 404);
        }

        // Remove default from all other addresses
        ShippingAddress::where('user_id', $request->user()->id)
            ->update(['is_default' => false]);

        // Set this address as default
        $address->update(['is_default' => true]);

        return response()->json([
            'status' => 'success',
            'message' => 'Default shipping address updated successfully',
            'data' => $address
        ]);
    }
}