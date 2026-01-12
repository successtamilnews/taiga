'use client'

import Image from 'next/image'
import Link from 'next/link'
import { useState } from 'react'
import { Heart, Star, ShoppingCart } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardFooter } from '@/components/ui/card'
import { Product } from '@/types'
import { formatPrice, calculateDiscount, getImageUrl } from '@/lib/utils'
import { useCartStore } from '@/store/cart'
import { useAppStore } from '@/store/app'

interface ProductCardProps {
  product: Product
  className?: string
}

export function ProductCard({ product, className }: ProductCardProps) {
  const [isLoading, setIsLoading] = useState(false)
  const { addItem } = useCartStore()
  const { addToWishlist, removeFromWishlist, isInWishlist } = useAppStore()

  const isWishlisted = isInWishlist(product.id)
  const hasDiscount = product.sale_price && product.sale_price < product.price
  const discount = hasDiscount ? calculateDiscount(product.price, product.sale_price!) : 0
  const displayPrice = product.sale_price || product.price
  const primaryImage = product.images.find(img => img.is_primary) || product.images[0]

  const handleAddToCart = async () => {
    setIsLoading(true)
    try {
      addItem(product)
      // Optional: Show toast notification
    } finally {
      setIsLoading(false)
    }
  }

  const handleWishlistToggle = () => {
    if (isWishlisted) {
      removeFromWishlist(product.id)
    } else {
      addToWishlist(product.id)
    }
  }

  return (
    <Card className={`group overflow-hidden hover:shadow-lg transition-shadow ${className}`}>
      <div className="relative">
        {/* Product Image */}
        <div className="aspect-square relative overflow-hidden bg-muted">
          {primaryImage ? (
            <Image
              src={getImageUrl(primaryImage.url)}
              alt={primaryImage.alt || product.name}
              fill
              className="object-cover group-hover:scale-105 transition-transform duration-300"
              sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center">
              <span className="text-muted-foreground">No Image</span>
            </div>
          )}
        </div>

        {/* Badges */}
        <div className="absolute top-3 left-3 flex flex-col space-y-2">
          {hasDiscount && (
            <span className="bg-destructive text-destructive-foreground text-xs font-semibold px-2 py-1 rounded">
              -{discount}%
            </span>
          )}
          {product.featured && (
            <span className="bg-primary text-primary-foreground text-xs font-semibold px-2 py-1 rounded">
              Featured
            </span>
          )}
          {!product.in_stock && (
            <span className="bg-muted text-muted-foreground text-xs font-semibold px-2 py-1 rounded">
              Out of Stock
            </span>
          )}
        </div>

        {/* Wishlist Button */}
        <Button
          variant="ghost"
          size="icon"
          className={`absolute top-3 right-3 opacity-0 group-hover:opacity-100 transition-opacity ${
            isWishlisted ? 'text-red-500' : 'text-muted-foreground'
          }`}
          onClick={handleWishlistToggle}
        >
          <Heart className={`h-4 w-4 ${isWishlisted ? 'fill-current' : ''}`} />
        </Button>
      </div>

      <CardContent className="p-4">
        {/* Vendor */}
        <div className="text-sm text-muted-foreground mb-1">
          <Link href={`/vendors/${product.vendor.slug}`} className="hover:text-primary">
            {product.vendor.name}
          </Link>
        </div>

        {/* Product Name */}
        <h3 className="font-semibold line-clamp-2 mb-2">
          <Link 
            href={`/products/${product.slug}`}
            className="hover:text-primary transition-colors"
          >
            {product.name}
          </Link>
        </h3>

        {/* Rating */}
        <div className="flex items-center space-x-2 mb-2">
          <div className="flex items-center">
            {[...Array(5)].map((_, i) => (
              <Star
                key={i}
                className={`h-3 w-3 ${
                  i < Math.floor(product.average_rating) 
                    ? 'fill-yellow-400 text-yellow-400' 
                    : 'text-muted-foreground'
                }`}
              />
            ))}
          </div>
          <span className="text-xs text-muted-foreground">
            ({product.total_reviews})
          </span>
        </div>

        {/* Price */}
        <div className="flex items-center space-x-2 mb-3">
          <span className="text-lg font-bold text-primary">
            {formatPrice(displayPrice)}
          </span>
          {hasDiscount && (
            <span className="text-sm text-muted-foreground line-through">
              {formatPrice(product.price)}
            </span>
          )}
        </div>

        {/* Short Description */}
        {product.short_description && (
          <p className="text-sm text-muted-foreground line-clamp-2">
            {product.short_description}
          </p>
        )}
      </CardContent>

      <CardFooter className="p-4 pt-0">
        <Button
          onClick={handleAddToCart}
          disabled={!product.in_stock || isLoading}
          variant="premium"
          className="w-full"
        >
          {isLoading ? (
            <div className="loading-spinner" />
          ) : (
            <>
              <ShoppingCart className="h-4 w-4 mr-2" />
              {product.in_stock ? 'Add to Cart' : 'Out of Stock'}
            </>
          )}
        </Button>
      </CardFooter>
    </Card>
  )
}