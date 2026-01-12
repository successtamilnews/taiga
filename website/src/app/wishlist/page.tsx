"use client"

import { useEffect, useState } from 'react'
import { Product } from '@/types'
import { ProductCard } from '@/components/product/product-card'
import { apiClient } from '@/services/api'
import { useAppStore } from '@/store/app'

export default function WishlistPage() {
  const { wishlist } = useAppStore()
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)

  const normalize = (p: any): Product => {
    const price = typeof p.price === 'string' ? parseFloat(p.price) : (p.price ?? 0)
    const salePrice = typeof p.sale_price === 'string' ? parseFloat(p.sale_price) : p.sale_price
    const vendorObj = p.vendor || {}
    const vendorName = vendorObj.name || vendorObj.business_name || 'Vendor'
    const vendorSlug = vendorObj.slug || (vendorName ? vendorName.toLowerCase().replace(/\s+/g, '-') : 'vendor')
    const images = Array.isArray(p.images) ? p.images.map((img: any) => ({
      id: String(img.id ?? ''), url: img.url ?? '', alt: img.alt_text ?? p.name ?? 'Image', is_primary: !!img.is_primary, sort_order: Number(img.sort_order ?? 0)
    })) : []
    return {
      id: String(p.id ?? ''), name: p.name ?? '', slug: p.slug ?? `product-${p.id ?? ''}`,
      description: p.description ?? '', short_description: p.short_description ?? '',
      price, sale_price: salePrice ?? undefined, sku: p.sku ?? '', stock_quantity: Number(p.stock_quantity ?? 0),
      manage_stock: !!(p.manage_stock ?? true), in_stock: p.stock_status ? p.stock_status === 'in_stock' : true,
      featured: !!p.is_featured, status: (p.status === 'approved' ? 'active' : 'draft'),
      vendor: { id: String(vendorObj.id ?? ''), name: vendorName, slug: vendorSlug, email: vendorObj.email || vendorObj.business_email || '', rating: Number(p.reviews_avg_rating ?? 0), total_reviews: Number(p.reviews_count ?? 0), total_products: 0, status: 'active', created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      categories: p.category ? [p.category] : [], images, attributes: [], variations: [], reviews: [], average_rating: Number(p.reviews_avg_rating ?? 0), total_reviews: Number(p.reviews_count ?? 0), tags: [], meta: {}, created_at: p.created_at || new Date().toISOString(), updated_at: p.updated_at || new Date().toISOString()
    }
  }

  useEffect(() => {
    const fetchWishlist = async () => {
      setLoading(true)
      if (!wishlist.length) {
        setProducts([])
        setLoading(false)
        return
      }
      // Fetch products by id in parallel
      const results = await Promise.allSettled(wishlist.map(id => apiClient.get(`/api/v1/products/${id}`)))
      const items = results
        .filter(r => r.status === 'fulfilled')
        .map((r: any) => (r.value?.data))
        .filter(Boolean)
      setProducts(items.map(normalize))
      setLoading(false)
    }
    fetchWishlist()
  }, [wishlist])

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h1 className="text-3xl font-bold mb-6">Your Wishlist</h1>
        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-80 bg-muted rounded animate-pulse" />
            ))}
          </div>
        ) : products.length === 0 ? (
          <div className="text-muted-foreground">Your wishlist is empty.</div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {products.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
