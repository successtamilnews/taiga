'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Image from 'next/image'
import { ArrowLeft, Lock, CreditCard, Smartphone, Building, Truck } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useCartStore } from '@/store/cart'
import { useAuthStore } from '@/store/auth'
import { formatPrice, getImageUrl } from '@/lib/utils'
import { paymentService, GooglePayService, ApplePayService, SampathBankService } from '@/services/payment'
import toast from 'react-hot-toast'
import Link from 'next/link'

export default function CheckoutPage() {
  const [step, setStep] = useState(1) // 1: Address, 2: Payment, 3: Review
  const [loading, setLoading] = useState(false)
  const [paymentMethods, setPaymentMethods] = useState<any[]>([])
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState('')
  const [isGooglePayReady, setIsGooglePayReady] = useState(false)
  const [isApplePayReady, setIsApplePayReady] = useState(false)

  const [shippingAddress, setShippingAddress] = useState({
    name: '',
    email: '',
    phone: '',
    street: '',
    city: '',
    state: '',
    zip_code: '',
    country: 'Sri Lanka'
  })

  const [cardDetails, setCardDetails] = useState({
    number: '',
    expiry: '',
    cvc: '',
    name: ''
  })

  const { cart, clearCart, getItemCount } = useCartStore()
  const { user, isAuthenticated } = useAuthStore()
  const router = useRouter()

  useEffect(() => {
    // Redirect to login if not authenticated
    if (!isAuthenticated) {
      router.push('/auth/login?redirect=/checkout')
      return
    }

    // Redirect to cart if empty
    if (cart.items.length === 0) {
      router.push('/cart')
      return
    }

    // Initialize payment methods
    initializePaymentMethods()

    // Pre-fill user data
    if (user) {
      setShippingAddress(prev => ({
        ...prev,
        name: user.name,
        email: user.email,
        phone: user.phone || '',
        ...(user.address && {
          street: user.address.street,
          city: user.address.city,
          state: user.address.state,
          zip_code: user.address.zip_code,
          country: user.address.country
        })
      }))
    }
  }, [isAuthenticated, cart.items.length, user, router])

  const initializePaymentMethods = async () => {
    try {
      // Initialize Google Pay
      try {
        const googlePayReady = await GooglePayService.initialize()
        setIsGooglePayReady(googlePayReady)
      } catch (error) {
        console.log('Google Pay not available:', error)
      }

      // Initialize Apple Pay
      try {
        const applePayReady = await ApplePayService.initialize()
        setIsApplePayReady(applePayReady)
      } catch (error) {
        console.log('Apple Pay not available:', error)
      }

      // Fetch available payment methods
      const response = await paymentService.getPaymentMethods()
      setPaymentMethods(response.data || [])
    } catch (error) {
      console.error('Error initializing payment methods:', error)
      // Set default payment methods
      setPaymentMethods([
        { id: 'credit_card', name: 'Credit/Debit Card', type: 'credit_card', enabled: true },
        { id: 'bank_transfer', name: 'Bank Transfer', type: 'bank_transfer', enabled: true },
        { id: 'cod', name: 'Cash on Delivery', type: 'cash_on_delivery', enabled: true }
      ])
    }
  }

  const handleGooglePay = async () => {
    try {
      setLoading(true)
      const paymentData = await GooglePayService.requestPayment(cart.total * 100, cart.currency)
      
      // Process payment with backend
      const result = await paymentService.processGooglePay(
        paymentData.paymentMethodData.tokenizationData.token,
        'temp-order-id'
      )

      if (result.success) {
        toast.success('Payment successful!')
        clearCart()
        router.push('/orders/success')
      } else {
        toast.error('Payment failed. Please try again.')
      }
    } catch (error: any) {
      console.error('Google Pay error:', error)
      toast.error(error.message || 'Payment cancelled or failed')
    } finally {
      setLoading(false)
    }
  }

  const handleApplePay = async () => {
    try {
      setLoading(true)
      const paymentData = await ApplePayService.requestPayment(cart.total * 100, cart.currency)
      
      // Process payment with backend
      const result = await paymentService.processApplePay(paymentData, 'temp-order-id')

      if (result.success) {
        toast.success('Payment successful!')
        clearCart()
        router.push('/orders/success')
      } else {
        toast.error('Payment failed. Please try again.')
      }
    } catch (error: any) {
      console.error('Apple Pay error:', error)
      toast.error(error.message || 'Payment cancelled or failed')
    } finally {
      setLoading(false)
    }
  }

  const handleSampathBankPayment = async () => {
    try {
      setLoading(true)
      
      const orderData = {
        amount: cart.total * 100,
        currency: cart.currency,
        order_id: 'temp-order-id',
        payment_method: 'sampath_bank',
        billing_address: shippingAddress
      }

      await SampathBankService.initiatePayment(orderData)
    } catch (error: any) {
      console.error('Sampath Bank error:', error)
      toast.error('Unable to process payment. Please try again.')
      setLoading(false)
    }
  }

  const handleCreditCardPayment = async () => {
    try {
      setLoading(true)
      
      const result = await paymentService.processCreditCard(cardDetails, 'temp-order-id')

      if (result.success) {
        toast.success('Payment successful!')
        clearCart()
        router.push('/orders/success')
      } else {
        toast.error('Payment failed. Please try again.')
      }
    } catch (error: any) {
      console.error('Credit card error:', error)
      toast.error(error.message || 'Payment failed. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const handleSubmitOrder = async () => {
    switch (selectedPaymentMethod) {
      case 'google_pay':
        await handleGooglePay()
        break
      case 'apple_pay':
        await handleApplePay()
        break
      case 'sampath_bank':
        await handleSampathBankPayment()
        break
      case 'credit_card':
        await handleCreditCardPayment()
        break
      case 'cod':
        toast.success('Order placed successfully!')
        clearCart()
        router.push('/orders/success')
        break
      default:
        toast.error('Please select a payment method')
    }
  }

  if (!isAuthenticated || cart.items.length === 0) {
    return null
  }

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center space-x-4">
            <Button variant="ghost" asChild>
              <Link href="/cart">
                <ArrowLeft className="h-4 w-4 mr-2" />
                Back to Cart
              </Link>
            </Button>
            <h1 className="text-3xl font-bold">Checkout</h1>
          </div>
          <div className="flex items-center space-x-2 text-sm text-muted-foreground">
            <Lock className="h-4 w-4" />
            <span>Secure Checkout</span>
          </div>
        </div>

        {/* Progress Indicator */}
        <div className="mb-8">
          <div className="flex items-center justify-center space-x-8">
            {[1, 2, 3].map((stepNumber) => (
              <div key={stepNumber} className="flex items-center">
                <div className={`
                  w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium
                  ${step >= stepNumber ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground'}
                `}>
                  {stepNumber}
                </div>
                <span className={`ml-2 text-sm ${step >= stepNumber ? 'text-foreground' : 'text-muted-foreground'}`}>
                  {stepNumber === 1 ? 'Shipping' : stepNumber === 2 ? 'Payment' : 'Review'}
                </span>
                {stepNumber < 3 && <div className="w-16 h-px bg-border mx-4" />}
              </div>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Step 1: Shipping Address */}
            {step === 1 && (
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <Truck className="h-5 w-5 mr-2" />
                    Shipping Address
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="text-sm font-medium">Full Name</label>
                      <Input
                        value={shippingAddress.name}
                        onChange={(e) => setShippingAddress({...shippingAddress, name: e.target.value})}
                        required
                      />
                    </div>
                    <div>
                      <label className="text-sm font-medium">Email</label>
                      <Input
                        type="email"
                        value={shippingAddress.email}
                        onChange={(e) => setShippingAddress({...shippingAddress, email: e.target.value})}
                        required
                      />
                    </div>
                    <div>
                      <label className="text-sm font-medium">Phone</label>
                      <Input
                        value={shippingAddress.phone}
                        onChange={(e) => setShippingAddress({...shippingAddress, phone: e.target.value})}
                        required
                      />
                    </div>
                    <div>
                      <label className="text-sm font-medium">Street Address</label>
                      <Input
                        value={shippingAddress.street}
                        onChange={(e) => setShippingAddress({...shippingAddress, street: e.target.value})}
                        required
                      />
                    </div>
                    <div>
                      <label className="text-sm font-medium">City</label>
                      <Input
                        value={shippingAddress.city}
                        onChange={(e) => setShippingAddress({...shippingAddress, city: e.target.value})}
                        required
                      />
                    </div>
                    <div>
                      <label className="text-sm font-medium">State/Province</label>
                      <Input
                        value={shippingAddress.state}
                        onChange={(e) => setShippingAddress({...shippingAddress, state: e.target.value})}
                        required
                      />
                    </div>
                    <div>
                      <label className="text-sm font-medium">Postal Code</label>
                      <Input
                        value={shippingAddress.zip_code}
                        onChange={(e) => setShippingAddress({...shippingAddress, zip_code: e.target.value})}
                        required
                      />
                    </div>
                    <div>
                      <label className="text-sm font-medium">Country</label>
                      <select
                        value={shippingAddress.country}
                        onChange={(e) => setShippingAddress({...shippingAddress, country: e.target.value})}
                        className="w-full border border-input bg-background px-3 py-2 rounded-md"
                      >
                        <option value="Sri Lanka">Sri Lanka</option>
                      </select>
                    </div>
                  </div>
                  <Button onClick={() => setStep(2)} className="w-full">
                    Continue to Payment
                  </Button>
                </CardContent>
              </Card>
            )}

            {/* Step 2: Payment Method */}
            {step === 2 && (
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <CreditCard className="h-5 w-5 mr-2" />
                    Payment Method
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                  {/* Quick Pay Options */}
                  <div className="space-y-3">
                    <h3 className="font-medium">Quick Pay Options</h3>
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                      {isGooglePayReady && (
                        <Button
                          variant="outline"
                          className="h-12 justify-start"
                          onClick={() => setSelectedPaymentMethod('google_pay')}
                        >
                          <div className="flex items-center space-x-2">
                            <Smartphone className="h-4 w-4" />
                            <span>Google Pay</span>
                          </div>
                        </Button>
                      )}
                      {isApplePayReady && (
                        <Button
                          variant="outline"
                          className="h-12 justify-start"
                          onClick={() => setSelectedPaymentMethod('apple_pay')}
                        >
                          <div className="flex items-center space-x-2">
                            <Smartphone className="h-4 w-4" />
                            <span>Apple Pay</span>
                          </div>
                        </Button>
                      )}
                      <Button
                        variant="outline"
                        className="h-12 justify-start"
                        onClick={() => setSelectedPaymentMethod('sampath_bank')}
                      >
                        <div className="flex items-center space-x-2">
                          <Building className="h-4 w-4" />
                          <span>Sampath Bank</span>
                        </div>
                      </Button>
                    </div>
                  </div>

                  {/* Traditional Payment Methods */}
                  <div className="space-y-4">
                    {/* Credit Card */}
                    <div className="border rounded-lg p-4">
                      <label className="flex items-center space-x-2">
                        <input
                          type="radio"
                          name="paymentMethod"
                          value="credit_card"
                          checked={selectedPaymentMethod === 'credit_card'}
                          onChange={(e) => setSelectedPaymentMethod(e.target.value)}
                        />
                        <span className="font-medium">Credit/Debit Card</span>
                      </label>
                      {selectedPaymentMethod === 'credit_card' && (
                        <div className="mt-4 space-y-3">
                          <Input
                            placeholder="Card Number"
                            value={cardDetails.number}
                            onChange={(e) => setCardDetails({...cardDetails, number: e.target.value})}
                          />
                          <div className="grid grid-cols-2 gap-3">
                            <Input
                              placeholder="MM/YY"
                              value={cardDetails.expiry}
                              onChange={(e) => setCardDetails({...cardDetails, expiry: e.target.value})}
                            />
                            <Input
                              placeholder="CVC"
                              value={cardDetails.cvc}
                              onChange={(e) => setCardDetails({...cardDetails, cvc: e.target.value})}
                            />
                          </div>
                          <Input
                            placeholder="Name on Card"
                            value={cardDetails.name}
                            onChange={(e) => setCardDetails({...cardDetails, name: e.target.value})}
                          />
                        </div>
                      )}
                    </div>

                    {/* Bank Transfer */}
                    <div className="border rounded-lg p-4">
                      <label className="flex items-center space-x-2">
                        <input
                          type="radio"
                          name="paymentMethod"
                          value="bank_transfer"
                          checked={selectedPaymentMethod === 'bank_transfer'}
                          onChange={(e) => setSelectedPaymentMethod(e.target.value)}
                        />
                        <span className="font-medium">Bank Transfer</span>
                      </label>
                    </div>

                    {/* Cash on Delivery */}
                    <div className="border rounded-lg p-4">
                      <label className="flex items-center space-x-2">
                        <input
                          type="radio"
                          name="paymentMethod"
                          value="cod"
                          checked={selectedPaymentMethod === 'cod'}
                          onChange={(e) => setSelectedPaymentMethod(e.target.value)}
                        />
                        <span className="font-medium">Cash on Delivery</span>
                      </label>
                      {selectedPaymentMethod === 'cod' && (
                        <p className="text-sm text-muted-foreground mt-2">
                          Pay when your order is delivered. Additional charges may apply.
                        </p>
                      )}
                    </div>
                  </div>

                  <div className="flex space-x-3">
                    <Button variant="outline" onClick={() => setStep(1)} className="flex-1">
                      Back
                    </Button>
                    <Button onClick={() => setStep(3)} className="flex-1" disabled={!selectedPaymentMethod}>
                      Review Order
                    </Button>
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Step 3: Review Order */}
            {step === 3 && (
              <Card>
                <CardHeader>
                  <CardTitle>Review Your Order</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  {/* Order Summary */}
                  <div className="space-y-4">
                    {cart.items.map((item) => {
                      const primaryImage = item.product.images.find(img => img.is_primary) || item.product.images[0]
                      
                      return (
                        <div key={item.id} className="flex items-center space-x-3 py-2">
                          <div className="w-16 h-16 relative bg-muted rounded">
                            {primaryImage && (
                              <Image
                                src={getImageUrl(primaryImage.url)}
                                alt={item.product.name}
                                fill
                                className="object-cover rounded"
                              />
                            )}
                          </div>
                          <div className="flex-1">
                            <h4 className="font-medium">{item.product.name}</h4>
                            <p className="text-sm text-muted-foreground">
                              Qty: {item.quantity} × {formatPrice(item.price)}
                            </p>
                          </div>
                          <span className="font-medium">{formatPrice(item.total)}</span>
                        </div>
                      )
                    })}
                  </div>

                  <div className="flex space-x-3">
                    <Button variant="outline" onClick={() => setStep(2)} className="flex-1">
                      Back
                    </Button>
                    <Button
                      onClick={handleSubmitOrder}
                      className="flex-1"
                      disabled={loading}
                    >
                      {loading ? 'Processing...' : 'Place Order'}
                    </Button>
                  </div>
                </CardContent>
              </Card>
            )}
          </div>

          {/* Order Summary Sidebar */}
          <div className="lg:col-span-1">
            <Card className="sticky top-4">
              <CardHeader>
                <CardTitle>Order Summary</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between">
                  <span>Items ({getItemCount()})</span>
                  <span>{formatPrice(cart.subtotal)}</span>
                </div>
                <div className="flex justify-between">
                  <span>Shipping</span>
                  <span>{cart.shipping === 0 ? 'Free' : formatPrice(cart.shipping)}</span>
                </div>
                <div className="flex justify-between">
                  <span>Tax</span>
                  <span>{formatPrice(cart.tax)}</span>
                </div>
                {cart.discount > 0 && (
                  <div className="flex justify-between text-destructive">
                    <span>Discount</span>
                    <span>-{formatPrice(cart.discount)}</span>
                  </div>
                )}
                <div className="border-t pt-3">
                  <div className="flex justify-between text-lg font-bold">
                    <span>Total</span>
                    <span>{formatPrice(cart.total)}</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  )
}