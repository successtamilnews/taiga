'use client'

import { useState } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import { Minus, Plus, Trash2, ShoppingBag, ArrowRight, ArrowLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { useCartStore } from '@/store/cart'
import { formatPrice, getImageUrl } from '@/lib/utils'

export default function CartPage() {
  const { cart, updateQuantity, removeItem, clearCart, getItemCount } = useCartStore()
  const [couponCode, setCouponCode] = useState('')
  const [isLoading, setIsLoading] = useState(false)

  const handleQuantityChange = (itemId: string, newQuantity: number) => {
    if (newQuantity < 1) return
    updateQuantity(itemId, newQuantity)
  }

  const handleApplyCoupon = async () => {
    setIsLoading(true)
    // Implement coupon logic here
    setTimeout(() => {
      setIsLoading(false)
    }, 1000)
  }

  if (cart.items.length === 0) {
    return (
      <div className="min-h-screen bg-muted/30">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-16 text-center">
          <div className="mb-8">
            <ShoppingBag className="h-24 w-24 text-muted-foreground mx-auto mb-4" />
            <h1 className="text-3xl font-bold mb-4">Your Cart is Empty</h1>
            <p className="text-muted-foreground text-lg">
              Looks like you haven't added any items to your cart yet.
            </p>
          </div>
          <Button asChild size="lg">
            <Link href="/products">
              Start Shopping
              <ArrowRight className="ml-2 h-4 w-4" />
            </Link>
          </Button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">Shopping Cart</h1>
          <p className="text-muted-foreground">
            {getItemCount()} {getItemCount() === 1 ? 'item' : 'items'} in your cart
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Cart Items */}
          <div className="lg:col-span-2 space-y-4">
            {cart.items.map((item) => {
              const primaryImage = item.product.images.find(img => img.is_primary) || item.product.images[0]
              
              return (
                <Card key={item.id}>
                  <CardContent className="p-6">
                    <div className="flex flex-col sm:flex-row gap-4">
                      {/* Product Image */}
                      <div className="flex-shrink-0">
                        <div className="w-24 h-24 relative bg-muted rounded-lg overflow-hidden">
                          {primaryImage ? (
                            <Image
                              src={getImageUrl(primaryImage.url)}
                              alt={primaryImage.alt || item.product.name}
                              fill
                              className="object-cover"
                            />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center">
                              <span className="text-muted-foreground text-sm">No Image</span>
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Product Info */}
                      <div className="flex-1 space-y-2">
                        <div>
                          <h3 className="font-semibold">
                            <Link 
                              href={`/products/${item.product.slug}`}
                              className="hover:text-primary transition-colors"
                            >
                              {item.product.name}
                            </Link>
                          </h3>
                          <p className="text-sm text-muted-foreground">
                            by {item.product.vendor.name}
                          </p>
                          {item.variation && (
                            <p className="text-sm text-muted-foreground">
                              Variation: {item.variation.name}
                            </p>
                          )}
                        </div>

                        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                          {/* Quantity Controls */}
                          <div className="flex items-center space-x-2">
                            <span className="text-sm font-medium">Quantity:</span>
                            <div className="flex items-center border rounded-md">
                              <Button
                                variant="ghost"
                                size="icon"
                                className="h-8 w-8"
                                onClick={() => handleQuantityChange(item.id, item.quantity - 1)}
                              >
                                <Minus className="h-3 w-3" />
                              </Button>
                              <Input
                                type="number"
                                value={item.quantity}
                                onChange={(e) => handleQuantityChange(item.id, parseInt(e.target.value) || 1)}
                                className="w-16 h-8 text-center border-0 focus:ring-0"
                                min={1}
                                max={item.product.stock_quantity}
                              />
                              <Button
                                variant="ghost"
                                size="icon"
                                className="h-8 w-8"
                                onClick={() => handleQuantityChange(item.id, item.quantity + 1)}
                                disabled={item.quantity >= item.product.stock_quantity}
                              >
                                <Plus className="h-3 w-3" />
                              </Button>
                            </div>
                          </div>

                          {/* Price and Remove */}
                          <div className="flex items-center justify-between sm:justify-end space-x-4">
                            <div className="text-right">
                              <p className="font-semibold">{formatPrice(item.total)}</p>
                              {item.quantity > 1 && (
                                <p className="text-sm text-muted-foreground">
                                  {formatPrice(item.price)} each
                                </p>
                              )}
                            </div>
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => removeItem(item.id)}
                              className="text-destructive hover:text-destructive"
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              )
            })}

            {/* Clear Cart */}
            <div className="flex justify-between items-center pt-4">
              <Button variant="outline" asChild>
                <Link href="/products">
                  <ArrowLeft className="mr-2 h-4 w-4" />
                  Continue Shopping
                </Link>
              </Button>
              <Button
                variant="destructive"
                onClick={clearCart}
                className="text-sm"
              >
                Clear Cart
              </Button>
            </div>
          </div>

          {/* Order Summary */}
          <div className="lg:col-span-1">
            <Card className="sticky top-4">
              <CardHeader>
                <CardTitle>Order Summary</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {/* Coupon Code */}
                <div>
                  <label className="text-sm font-medium">Coupon Code</label>
                  <div className="flex mt-1">
                    <Input
                      type="text"
                      placeholder="Enter code"
                      value={couponCode}
                      onChange={(e) => setCouponCode(e.target.value)}
                      className="rounded-r-none"
                    />
                    <Button
                      onClick={handleApplyCoupon}
                      disabled={!couponCode.trim() || isLoading}
                      className="rounded-l-none"
                    >
                      {isLoading ? 'Applying...' : 'Apply'}
                    </Button>
                  </div>
                </div>

                {/* Summary Breakdown */}
                <div className="space-y-3 pt-4 border-t">
                  <div className="flex justify-between">
                    <span>Subtotal ({getItemCount()} items)</span>
                    <span>{formatPrice(cart.subtotal)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Shipping</span>
                    <span>
                      {cart.shipping === 0 ? 'Free' : formatPrice(cart.shipping)}
                    </span>
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
                  <div className="flex justify-between text-lg font-bold pt-3 border-t">
                    <span>Total</span>
                    <span>{formatPrice(cart.total)}</span>
                  </div>
                </div>

                {/* Shipping Info */}
                {cart.shipping === 0 && (
                  <div className="bg-green-50 border border-green-200 rounded-md p-3">
                    <p className="text-sm text-green-700 font-medium">
                      🎉 You qualify for FREE shipping!
                    </p>
                  </div>
                )}

                {/* Checkout Button */}
                <Button className="w-full" size="lg" asChild>
                  <Link href="/checkout">
                    Proceed to Checkout
                    <ArrowRight className="ml-2 h-4 w-4" />
                  </Link>
                </Button>

                {/* Payment Methods */}
                <div className="text-center pt-4">
                  <p className="text-sm text-muted-foreground mb-2">We accept:</p>
                  <div className="flex justify-center space-x-2">
                    <div className="bg-muted px-2 py-1 rounded text-xs">Google Pay</div>
                    <div className="bg-muted px-2 py-1 rounded text-xs">Apple Pay</div>
                    <div className="bg-muted px-2 py-1 rounded text-xs">Cards</div>
                    <div className="bg-muted px-2 py-1 rounded text-xs">Bank Transfer</div>
                  </div>
                </div>

                {/* Security Badge */}
                <div className="text-center text-sm text-muted-foreground">
                  <p>🔒 Secure checkout with 256-bit SSL encryption</p>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  )
}