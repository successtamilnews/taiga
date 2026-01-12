"use client"

import { useEffect, useMemo, useState } from 'react'
import Link from 'next/link'
import { useParams } from 'next/navigation'
import { apiClient } from '@/services/api'
import { Product } from '@/types'
import { ProductCard } from '@/components/product/product-card'
import { Pagination } from '@/components/ui/pagination'

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

export default function VendorDetailPage() {
  const params = useParams<{ slug: string }>()
  const slug = params?.slug
  const [vendor, setVendor] = useState<any | null>(null)
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const [currentPage, setCurrentPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)

  useEffect(() => {
    const fetchData = async () => {
      if (!slug) return
      setLoading(true)
      // Fetch vendors and find by slug/name fallback
      const vRes = await apiClient.get<any[]>('/api/vendors')
      const vendors = Array.isArray(vRes.data) ? vRes.data : (vRes as any)?.data?.data || []
      let v = vendors.find((x: any) => x.slug === slug)
      if (!v) {
        v = vendors.find((x: any) => (x.business_name || x.name || '').toLowerCase().replace(/\s+/g, '-') === slug)
      }
      if (v) {
        setVendor(v)
        // Fetch products by vendor id via products index filter
        const prodRes = await apiClient.get<any>('/api/v1/products', { vendor: v.id, per_page: 24, page: currentPage })
        const list = Array.isArray(prodRes.data) ? prodRes.data : (prodRes as any)?.data?.data || []
        setProducts(list.map(normalize))
        const lastPage = (prodRes as any)?.data?.last_page || (prodRes as any)?.meta?.last_page || 1
        setTotalPages(lastPage)
      } else {
        setVendor(null)
        setProducts([])
        setTotalPages(1)
      }
      setLoading(false)
    }
    fetchData()
  }, [slug, currentPage])

  const title = useMemo(() => vendor?.business_name || vendor?.name || 'Vendor', [vendor])

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        {/* Breadcrumbs */}
        <nav className="text-sm text-muted-foreground mb-4">
          <Link href="/" className="hover:underline">Home</Link>
          <span className="mx-2">/</span>
          <Link href="/vendors" className="hover:underline">Vendors</Link>
          <span className="mx-2">/</span>
          <span className="text-foreground">{title}</span>
        </nav>
        <h1 className="text-3xl font-bold mb-6">{title}</h1>
        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-80 bg-muted rounded animate-pulse" />
            ))}
          </div>
        ) : products.length === 0 ? (
          <div className="text-muted-foreground">No products found for this vendor.</div>
        ) : (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {products.map((p) => (
                <ProductCard key={p.id} product={p} />
              ))}
            </div>
            <Pagination currentPage={currentPage} totalPages={totalPages} onChange={setCurrentPage} />
          </>
        )}
      </div>
    </div>
  )
}
