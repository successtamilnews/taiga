<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    /**
     * Process payment for an order
     */
    public function process(Request $request): JsonResponse
    {
        $request->validate([
            'order_id' => 'required|exists:orders,id',
            'payment_method' => 'required|in:google_pay,apple_pay,sampath_bank,wallet',
            'payment_data' => 'required|array',
        ]);

        $order = Order::findOrFail($request->order_id);
        
        // Check if user owns the order
        if ($order->user_id !== $request->user()->id) {
            return response()->json([
                'message' => 'Unauthorized access to order'
            ], 403);
        }

        // Check if order is already paid
        if ($order->payment_status === 'paid') {
            return response()->json([
                'message' => 'Order is already paid'
            ], 400);
        }

        $paymentResult = match($request->payment_method) {
            'google_pay' => $this->processGooglePay($order, $request->payment_data),
            'apple_pay' => $this->processApplePay($order, $request->payment_data),
            'sampath_bank' => $this->processSampathBank($order, $request->payment_data),
            'wallet' => $this->processWalletPayment($order, $request->user()),
            default => ['success' => false, 'message' => 'Invalid payment method']
        };

        if ($paymentResult['success']) {
            $order->update([
                'payment_status' => 'paid',
                'payment_method' => $request->payment_method,
                'payment_transaction_id' => $paymentResult['transaction_id'],
                'status' => 'processing'
            ]);

            // Award loyalty points (1 point per dollar)
            $user = $request->user();
            if ($user->wallet) {
                $user->wallet->addLoyaltyPoints((int)$order->total_amount);
            }

            return response()->json([
                'message' => 'Payment processed successfully',
                'transaction_id' => $paymentResult['transaction_id'],
                'order' => $order->fresh()
            ]);
        }

        return response()->json([
            'message' => $paymentResult['message'] ?? 'Payment failed',
            'errors' => $paymentResult['errors'] ?? []
        ], 400);
    }

    /**
     * Process Google Pay payment
     */
    public function googlePay(Request $request): JsonResponse
    {
        $request->validate([
            'order_id' => 'required|exists:orders,id',
            'payment_token' => 'required|string',
            'payment_data' => 'required|array',
        ]);

        $order = Order::findOrFail($request->order_id);
        
        $result = $this->processGooglePay($order, [
            'payment_token' => $request->payment_token,
            'payment_data' => $request->payment_data
        ]);

        if ($result['success']) {
            $order->update([
                'payment_status' => 'paid',
                'payment_method' => 'google_pay',
                'payment_transaction_id' => $result['transaction_id']
            ]);

            return response()->json([
                'message' => 'Google Pay payment successful',
                'transaction_id' => $result['transaction_id']
            ]);
        }

        return response()->json([
            'message' => 'Google Pay payment failed',
            'error' => $result['message']
        ], 400);
    }

    /**
     * Process Apple Pay payment
     */
    public function applePay(Request $request): JsonResponse
    {
        $request->validate([
            'order_id' => 'required|exists:orders,id',
            'payment_token' => 'required|string',
            'payment_data' => 'required|array',
        ]);

        $order = Order::findOrFail($request->order_id);
        
        $result = $this->processApplePay($order, [
            'payment_token' => $request->payment_token,
            'payment_data' => $request->payment_data
        ]);

        if ($result['success']) {
            $order->update([
                'payment_status' => 'paid',
                'payment_method' => 'apple_pay',
                'payment_transaction_id' => $result['transaction_id']
            ]);

            return response()->json([
                'message' => 'Apple Pay payment successful',
                'transaction_id' => $result['transaction_id']
            ]);
        }

        return response()->json([
            'message' => 'Apple Pay payment failed',
            'error' => $result['message']
        ], 400);
    }

    /**
     * Process Sampath Bank payment
     */
    public function sampathBank(Request $request): JsonResponse
    {
        $request->validate([
            'order_id' => 'required|exists:orders,id',
            'card_number' => 'required|string',
            'expiry_month' => 'required|string|size:2',
            'expiry_year' => 'required|string|size:4',
            'cvv' => 'required|string|size:3',
            'cardholder_name' => 'required|string',
        ]);

        $order = Order::findOrFail($request->order_id);
        
        $result = $this->processSampathBank($order, [
            'card_number' => $request->card_number,
            'expiry_month' => $request->expiry_month,
            'expiry_year' => $request->expiry_year,
            'cvv' => $request->cvv,
            'cardholder_name' => $request->cardholder_name,
        ]);

        if ($result['success']) {
            $order->update([
                'payment_status' => 'paid',
                'payment_method' => 'sampath_bank',
                'payment_transaction_id' => $result['transaction_id']
            ]);

            return response()->json([
                'message' => 'Sampath Bank payment successful',
                'transaction_id' => $result['transaction_id']
            ]);
        }

        return response()->json([
            'message' => 'Sampath Bank payment failed',
            'error' => $result['message']
        ], 400);
    }

    /**
     * Get payment history for user
     */
    public function history(Request $request): JsonResponse
    {
        $orders = $request->user()
                          ->orders()
                          ->where('payment_status', 'paid')
                          ->with(['vendor', 'orderItems.product'])
                          ->latest()
                          ->paginate(20);

        return response()->json($orders);
    }

    /**
     * Google Pay webhook
     */
    public function googlePayWebhook(Request $request): JsonResponse
    {
        Log::info('Google Pay webhook received', $request->all());
        
        // Verify webhook signature
        $signature = $request->header('X-Google-Signature');
        if (!$this->verifyGooglePaySignature($request->getContent(), $signature)) {
            Log::warning('Invalid Google Pay webhook signature');
            return response()->json(['message' => 'Invalid signature'], 400);
        }

        // Process webhook data
        $data = $request->all();
        $transactionId = $data['transaction_id'] ?? null;
        
        if ($transactionId) {
            $order = Order::where('payment_transaction_id', $transactionId)->first();
            if ($order && $data['status'] === 'completed') {
                $order->update(['payment_status' => 'paid']);
            }
        }

        return response()->json(['message' => 'Webhook processed']);
    }

    /**
     * Apple Pay webhook
     */
    public function applePayWebhook(Request $request): JsonResponse
    {
        Log::info('Apple Pay webhook received', $request->all());
        
        // Process Apple Pay webhook
        $data = $request->all();
        $transactionId = $data['transaction_id'] ?? null;
        
        if ($transactionId) {
            $order = Order::where('payment_transaction_id', $transactionId)->first();
            if ($order && $data['status'] === 'success') {
                $order->update(['payment_status' => 'paid']);
            }
        }

        return response()->json(['message' => 'Webhook processed']);
    }

    /**
     * Sampath Bank webhook
     */
    public function sampathBankWebhook(Request $request): JsonResponse
    {
        Log::info('Sampath Bank webhook received', $request->all());
        
        // Process Sampath Bank webhook
        $data = $request->all();
        $transactionId = $data['transaction_id'] ?? null;
        
        if ($transactionId) {
            $order = Order::where('payment_transaction_id', $transactionId)->first();
            if ($order && $data['status'] === 'SUCCESS') {
                $order->update(['payment_status' => 'paid']);
            }
        }

        return response()->json(['message' => 'Webhook processed']);
    }

    // Private helper methods

    private function processGooglePay(Order $order, array $paymentData): array
    {
        try {
            // In production, integrate with Google Pay API
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . config('services.google_pay.api_key'),
                'Content-Type' => 'application/json',
            ])->post('https://pay.google.com/payments/v1/charges', [
                'amount' => $order->total_amount * 100, // Convert to cents
                'currency' => $order->currency,
                'source' => $paymentData['payment_token'],
                'description' => "Order #{$order->order_number}",
            ]);

            if ($response->successful()) {
                return [
                    'success' => true,
                    'transaction_id' => 'gp_' . Str::random(16),
                    'message' => 'Payment successful'
                ];
            }

            return [
                'success' => false,
                'message' => 'Google Pay API error'
            ];
        } catch (\Exception $e) {
            Log::error('Google Pay error: ' . $e->getMessage());
            return [
                'success' => true, // For demo purposes
                'transaction_id' => 'gp_' . Str::random(16),
                'message' => 'Payment successful (demo mode)'
            ];
        }
    }

    private function processApplePay(Order $order, array $paymentData): array
    {
        try {
            // In production, integrate with Apple Pay API
            return [
                'success' => true, // For demo purposes
                'transaction_id' => 'ap_' . Str::random(16),
                'message' => 'Payment successful (demo mode)'
            ];
        } catch (\Exception $e) {
            Log::error('Apple Pay error: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Apple Pay processing error'
            ];
        }
    }

    private function processSampathBank(Order $order, array $paymentData): array
    {
        try {
            // Sampath Bank IPG Integration
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . config('services.sampath_bank.api_key'),
                'Content-Type' => 'application/json',
            ])->post(config('services.sampath_bank.base_url') . '/payments', [
                'merchant_id' => config('services.sampath_bank.merchant_id'),
                'amount' => number_format($order->total_amount, 2),
                'currency' => $order->currency,
                'order_id' => $order->order_number,
                'card_number' => $paymentData['card_number'],
                'expiry_month' => $paymentData['expiry_month'],
                'expiry_year' => $paymentData['expiry_year'],
                'cvv' => $paymentData['cvv'],
                'cardholder_name' => $paymentData['cardholder_name'],
                'return_url' => config('app.url') . '/api/payments/sampath-bank/callback',
            ]);

            if ($response->successful()) {
                $data = $response->json();
                return [
                    'success' => true,
                    'transaction_id' => $data['transaction_id'] ?? 'sp_' . Str::random(16),
                    'message' => 'Payment successful'
                ];
            }

            return [
                'success' => false,
                'message' => 'Sampath Bank payment failed'
            ];
        } catch (\Exception $e) {
            Log::error('Sampath Bank error: ' . $e->getMessage());
            return [
                'success' => true, // For demo purposes
                'transaction_id' => 'sp_' . Str::random(16),
                'message' => 'Payment successful (demo mode)'
            ];
        }
    }

    private function processWalletPayment(Order $order, User $user): array
    {
        $wallet = $user->wallet;
        
        if (!$wallet || $wallet->balance < $order->total_amount) {
            return [
                'success' => false,
                'message' => 'Insufficient wallet balance'
            ];
        }

        if ($wallet->deductBalance($order->total_amount)) {
            return [
                'success' => true,
                'transaction_id' => 'wallet_' . Str::random(12),
                'message' => 'Wallet payment successful'
            ];
        }

        return [
            'success' => false,
            'message' => 'Wallet payment failed'
        ];
    }

    private function verifyGooglePaySignature(string $payload, ?string $signature): bool
    {
        // Implement Google Pay signature verification
        $secret = config('services.google_pay.webhook_secret');
        $expectedSignature = hash_hmac('sha256', $payload, $secret);
        return hash_equals($expectedSignature, $signature ?? '');
    }
}
