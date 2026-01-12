'use client'

import { useState, useEffect } from 'react'
import { useSearchParams } from 'next/navigation'
import { Filter, Grid, List, Search, SlidersHorizontal } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ProductCard } from '@/components/product/product-card'
import { Pagination } from '@/components/ui/pagination'
import { Product, SearchFilters, Category } from '@/types'
import { productService } from '@/services/products'
import { useAppStore } from '@/store/app'

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [showFilters, setShowFilters] = useState(false)
  const [filters, setFilters] = useState<SearchFilters>({})
  const [currentPage, setCurrentPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [categoryOptions, setCategoryOptions] = useState<Category[]>([])

  const searchParams = useSearchParams()
  const { searchQuery, setSearchQuery } = useAppStore()

  useEffect(() => {
    // Load categories for filter from backend (parents only)
    (async () => {
      try {
        const res = await fetch((process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000') + '/api/v1/categories?parent_only=1')
        const json = await res.json()
        const list = Array.isArray(json?.data) ? json.data : []
        setCategoryOptions(list)
      } catch (e) {
        setCategoryOptions([])
      }
    })()

    const fetchProducts = async () => {
      setLoading(true)
      try {
        const response = await productService.getProducts({
          ...filters,
          page: currentPage,
          per_page: 20
        })
        const normalizeProduct = (p: any): Product => {
          const price = typeof p.price === 'string' ? parseFloat(p.price) : (p.price ?? 0)
          const salePrice = typeof p.sale_price === 'string' ? parseFloat(p.sale_price) : p.sale_price
          const vendorObj = p.vendor || {}
          const vendorName = vendorObj.name || vendorObj.business_name || 'Vendor'
          const vendorSlug = vendorObj.slug || (vendorName ? vendorName.toLowerCase().replace(/\s+/g, '-') : 'vendor')
          const images = Array.isArray(p.images) ? p.images.map((img: any) => ({
            id: String(img.id ?? ''),
            url: img.url ?? '',
            alt: img.alt_text ?? p.name ?? 'Image',
            is_primary: Boolean(img.is_primary),
            sort_order: Number(img.sort_order ?? 0)
          })) : []
          const statusMap = (s: string) => {
            if (s === 'approved') return 'active'
            if (s === 'rejected') return 'inactive'
            return 'draft'
          }
          return {
            id: String(p.id ?? ''),
            name: p.name ?? '',
            slug: p.slug ?? `product-${p.id ?? ''}`,
            description: p.description ?? '',
            short_description: p.short_description ?? '',
            price: price,
            sale_price: salePrice ?? undefined,
            sku: p.sku ?? '',
            stock_quantity: Number(p.stock_quantity ?? 0),
            manage_stock: Boolean(p.manage_stock ?? true),
            in_stock: (p.stock_status ? p.stock_status === 'in_stock' : true),
            featured: Boolean(p.is_featured),
            status: statusMap(p.status),
            vendor: {
              id: String(vendorObj.id ?? ''),
              name: vendorName,
              slug: vendorSlug,
              email: vendorObj.email || vendorObj.business_email || '',
              rating: Number(p.reviews_avg_rating ?? 0),
              total_reviews: Number(p.reviews_count ?? 0),
              total_products: Number(vendorObj.total_products ?? 0),
              status: (vendorObj.status === 'approved' ? 'active' : 'pending'),
              created_at: vendorObj.created_at || new Date().toISOString(),
              updated_at: vendorObj.updated_at || new Date().toISOString(),
            },
            categories: p.category ? [p.category] : [],
            images,
            attributes: Array.isArray(p.attributes) ? p.attributes.map((a: any) => ({
              id: String(a.id ?? ''),
              name: a.name ?? '',
              value: typeof a.value === 'string' ? a.value : String(a.value ?? ''),
              type: a.type ?? 'text'
            })) : [],
            variations: [],
            reviews: [],
            average_rating: Number(p.reviews_avg_rating ?? 0),
            total_reviews: Number(p.reviews_count ?? 0),
            tags: [],
            meta: {},
            created_at: p.created_at || new Date().toISOString(),
            updated_at: p.updated_at || new Date().toISOString(),
          }
        }

        const list = Array.isArray(response.data)
          ? response.data
          : ((response as any).data?.data ?? [])

        setProducts(list.map(normalizeProduct))
        setTotalPages((response as any)?.data?.last_page || response.meta?.last_page || 1)
      } catch (error) {
        console.error('Error fetching products:', error)
        // Use mock data if API is not available
        setProducts(mockProducts)
      } finally {
        setLoading(false)
      }
    }

    fetchProducts()
  }, [filters, currentPage])

  // Mock products for demonstration
  const mockProducts: Product[] = Array.from({ length: 12 }, (_, i) => ({
    id: `${i + 1}`,
    name: `Sample Product ${i + 1}`,
    slug: `sample-product-${i + 1}`,
    description: 'This is a sample product description with detailed information about the product features and benefits.',
    price: 25000 + (i * 5000),
    sale_price: i % 3 === 0 ? 20000 + (i * 4000) : undefined,
    sku: `SKU-${i + 1}`,
    stock_quantity: 10 + i,
    manage_stock: true,
    in_stock: true,
    featured: i % 4 === 0,
    status: 'active',
    vendor: {
      id: `${i + 1}`,
      name: `Vendor ${i + 1}`,
      slug: `vendor-${i + 1}`,
      email: `vendor${i + 1}@example.com`,
      rating: 4.0 + (i % 10) * 0.1,
      total_reviews: 50 + i * 5,
      total_products: 10 + i,
      status: 'active',
      created_at: '2024-01-01',
      updated_at: '2024-01-01'
    },
    categories: [],
    images: [{ 
      id: `${i + 1}`, 
      url: `/images/placeholder-product-${(i % 4) + 1}.svg`, 
      alt: `Product ${i + 1}`, 
      is_primary: true, 
      sort_order: 1 
    }],
    attributes: [],
    reviews: [],
    average_rating: 4.0 + (i % 5),
    total_reviews: 10 + i * 2,
    tags: ['electronics', 'gadget', 'popular'],
    meta: { title: `Product ${i + 1}`, description: 'Sample product' },
    created_at: '2024-01-01',
    updated_at: '2024-01-01'
  }))

  // Categories now sourced dynamically via categoryOptions

  const priceRanges = [
    { label: 'Under Rs. 10,000', min: 0, max: 10000 },
    { label: 'Rs. 10,000 - Rs. 25,000', min: 10000, max: 25000 },
    { label: 'Rs. 25,000 - Rs. 50,000', min: 25000, max: 50000 },
    { label: 'Rs. 50,000 - Rs. 100,000', min: 50000, max: 100000 },
    { label: 'Over Rs. 100,000', min: 100000, max: undefined }
  ]

  const sortOptions = [
    { value: 'newest', label: 'Newest First' },
    { value: 'price', label: 'Price: Low to High' },
    { value: 'price-desc', label: 'Price: High to Low' },
    { value: 'rating', label: 'Highest Rated' },
    { value: 'name', label: 'Name: A to Z' }
  ]

  const handleFilterChange = (newFilters: Partial<SearchFilters>) => {
    setFilters({ ...filters, ...newFilters })
    setCurrentPage(1)
  }

  const clearFilters = () => {
    setFilters({})
    setCurrentPage(1)
  }

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-4">All Products</h1>
          
          {/* Search and Filters Bar */}
          <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
            <div className="flex-1 max-w-md">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
                <Input
                  type="text"
                  placeholder="Search products..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
            
            <div className="flex items-center space-x-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowFilters(!showFilters)}
                className="md:hidden"
              >
                <SlidersHorizontal className="h-4 w-4 mr-2" />
                Filters
              </Button>
              
              <div className="flex items-center border rounded-md">
                <Button
                  variant={viewMode === 'grid' ? 'default' : 'ghost'}
                  size="sm"
                  onClick={() => setViewMode('grid')}
                >
                  <Grid className="h-4 w-4" />
                </Button>
                <Button
                  variant={viewMode === 'list' ? 'default' : 'ghost'}
                  size="sm"
                  onClick={() => setViewMode('list')}
                >
                  <List className="h-4 w-4" />
                </Button>
              </div>
              
              <select
                value={filters.sort || 'newest'}
                onChange={(e) => handleFilterChange({ sort: e.target.value as any })}
                className="border border-input bg-background px-3 py-2 rounded-md text-sm"
              >
                {sortOptions.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          {/* Sidebar Filters */}
          <div className={`lg:col-span-1 ${showFilters ? 'block' : 'hidden lg:block'}`}>
            <Card className="sticky top-4">
              <CardHeader>
                <CardTitle className="flex items-center justify-between">
                  <span>Filters</span>
                  <Button variant="ghost" size="sm" onClick={clearFilters}>
                    Clear All
                  </Button>
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                {/* Categories */}
                <div>
                  <h3 className="font-semibold mb-3">Categories</h3>
                  <div className="space-y-2">
                    {categoryOptions.map((cat) => (
                      <label key={cat.id} className="flex items-center space-x-2">
                        <input
                          type="checkbox"
                          checked={filters.category === String(cat.id)}
                          onChange={(e) =>
                            handleFilterChange({
                              category: e.target.checked ? String(cat.id) : undefined
                            })
                          }
                          className="rounded"
                        />
                        <span className="text-sm">{cat.name}</span>
                      </label>
                    ))}
                  </div>
                </div>

                {/* Price Range */}
                <div>
                  <h3 className="font-semibold mb-3">Price Range</h3>
                  <div className="space-y-2">
                    {priceRanges.map((range, index) => (
                      <label key={index} className="flex items-center space-x-2">
                        <input
                          type="radio"
                          name="priceRange"
                          checked={filters.min_price === range.min && filters.max_price === range.max}
                          onChange={() =>
                            handleFilterChange({
                              min_price: range.min,
                              max_price: range.max
                            })
                          }
                          className="rounded"
                        />
                        <span className="text-sm">{range.label}</span>
                      </label>
                    ))}
                  </div>
                </div>

                {/* Rating */}
                <div>
                  <h3 className="font-semibold mb-3">Rating</h3>
                  <div className="space-y-2">
                    {[4, 3, 2, 1].map((rating) => (
                      <label key={rating} className="flex items-center space-x-2">
                        <input
                          type="radio"
                          name="rating"
                          checked={filters.rating === rating}
                          onChange={() => handleFilterChange({ rating })}
                          className="rounded"
                        />
                        <span className="text-sm">{rating}+ Stars</span>
                      </label>
                    ))}
                  </div>
                </div>

                {/* Availability */}
                <div>
                  <h3 className="font-semibold mb-3">Availability</h3>
                  <div className="space-y-2">
                    <label className="flex items-center space-x-2">
                      <input
                        type="checkbox"
                        checked={filters.in_stock}
                        onChange={(e) => handleFilterChange({ in_stock: e.target.checked })}
                        className="rounded"
                      />
                      <span className="text-sm">In Stock Only</span>
                    </label>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Products Grid */}
          <div className="lg:col-span-3">
            {loading ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {Array.from({ length: 6 }).map((_, i) => (
                  <div key={i} className="animate-pulse">
                    <div className="bg-muted rounded-lg h-80"></div>
                  </div>
                ))}
              </div>
            ) : (
              <>
                <div className="mb-4 flex justify-between items-center">
                  <p className="text-sm text-muted-foreground">
                    Showing {products.length} products
                  </p>
                </div>
                
                <div className={
                  viewMode === 'grid'
                    ? 'grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6'
                    : 'space-y-4'
                }>
                  {products.map((product) => (
                    <ProductCard
                      key={product.id}
                      product={product}
                      className={viewMode === 'list' ? 'flex-row' : ''}
                    />
                  ))}
                </div>

                <Pagination currentPage={currentPage} totalPages={totalPages} onChange={setCurrentPage} />
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}