'use client'

import { useState, useEffect } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import { 
  ChevronRight, 
  Star, 
  Truck, 
  Shield, 
  CreditCard, 
  Users, 
  TrendingUp,
  Heart,
  ArrowRight
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { ProductCard } from '@/components/product/product-card'
import { Product, Category, Vendor } from '@/types'
import { productService } from '@/services/products'

export default function HomePage() {
  const [featuredProducts, setFeaturedProducts] = useState<Product[]>([])
  const [onSaleProducts, setOnSaleProducts] = useState<Product[]>([])
  const [newestProducts, setNewestProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)

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

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [featured, onSale, newest] = await Promise.all([
          productService.getFeaturedProducts(8),
          productService.getProductsOnSale(8),
          productService.getNewestProducts(8)
        ])

        setFeaturedProducts((featured.data || []).map(normalizeProduct))
        setOnSaleProducts((onSale.data || []).map(normalizeProduct))
        setNewestProducts((newest.data || []).map(normalizeProduct))
      } catch (error) {
        console.error('Error fetching data:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [])

  // Mock data for demonstration
  const mockFeaturedProducts: Product[] = [
    {
      id: '1',
      name: 'iPhone 15 Pro Max',
      slug: 'iphone-15-pro-max',
      description: 'Latest iPhone with advanced camera system',
      price: 450000,
      sale_price: 420000,
      sku: 'IP15PM',
      stock_quantity: 10,
      manage_stock: true,
      in_stock: true,
      featured: true,
      status: 'active',
      vendor: {
        id: '1',
        name: 'TechWorld',
        slug: 'techworld',
        email: 'contact@techworld.lk',
        rating: 4.8,
        total_reviews: 150,
        total_products: 25,
        status: 'active',
        created_at: '2024-01-01',
        updated_at: '2024-01-01'
      },
      categories: [],
      images: [{ id: '1', url: '/images/placeholder-phone.svg', alt: 'iPhone 15 Pro Max', is_primary: true, sort_order: 1 }],
      attributes: [],
      reviews: [],
      average_rating: 4.8,
      total_reviews: 45,
      tags: ['smartphone', 'apple', 'premium'],
      meta: { title: 'iPhone 15 Pro Max', description: 'Latest iPhone model' },
      created_at: '2024-01-01',
      updated_at: '2024-01-01'
    }
  ]

  const categories = [
    { name: 'Electronics', icon: '📱', count: 1250, color: 'bg-blue-500' },
    { name: 'Fashion', icon: '👔', count: 850, color: 'bg-pink-500' },
    { name: 'Home & Garden', icon: '🏠', count: 650, color: 'bg-green-500' },
    { name: 'Sports', icon: '⚽', count: 450, color: 'bg-orange-500' },
    { name: 'Beauty', icon: '💄', count: 380, color: 'bg-purple-500' },
    { name: 'Books', icon: '📚', count: 720, color: 'bg-indigo-500' },
    { name: 'Toys', icon: '🧸', count: 320, color: 'bg-yellow-500' },
    { name: 'Automotive', icon: '🚗', count: 290, color: 'bg-gray-500' }
  ]

  const features = [
    {
      icon: Truck,
      title: 'Free Island-wide Delivery',
      description: 'Free shipping on orders over Rs. 5,000'
    },
    {
      icon: Shield,
      title: 'Secure Payments',
      description: 'Multiple payment options including Google Pay & Apple Pay'
    },
    {
      icon: CreditCard,
      title: 'Easy Returns',
      description: '30-day hassle-free return policy'
    },
    {
      icon: Users,
      title: 'Trusted Vendors',
      description: 'Verified sellers across Sri Lanka'
    }
  ]

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="loading-spinner" />
      </div>
    )
  }

  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <section className="relative bg-gradient-to-r from-primary to-blue-600 text-white py-20 overflow-hidden">
        <div className="absolute inset-0">
          <div className="absolute inset-0 bg-black/20" />
          <div className="w-full h-full bg-gradient-to-br from-primary/80 to-blue-600/80" />
        </div>
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div className="space-y-6">
              <h1 className="text-4xl md:text-6xl font-bold leading-tight">
                Discover Amazing Products from
                <span className="block text-white">Trusted Vendors</span>
              </h1>
              <p className="text-xl text-white/90 max-w-lg">
                Sri Lanka's premier multi-vendor marketplace with over 10,000 products 
                from verified sellers across the island.
              </p>
              <div className="flex flex-col sm:flex-row gap-4">
                <Button size="lg" variant="premium" asChild>
                  <Link href="/products">
                    Start Shopping
                    <ChevronRight className="ml-2 h-4 w-4" />
                  </Link>
                </Button>
                <Button size="lg" variant="outline" className="text-white border-white hover:bg-white hover:text-primary" asChild>
                  <Link href="/vendors">Become a Vendor</Link>
                </Button>
              </div>
              <div className="flex items-center space-x-8 text-sm">
                <div className="flex items-center space-x-2">
                  <Users className="h-5 w-5" />
                  <span>500+ Vendors</span>
                </div>
                <div className="flex items-center space-x-2">
                  <TrendingUp className="h-5 w-5" />
                  <span>10,000+ Products</span>
                </div>
                <div className="flex items-center space-x-2">
                  <Heart className="h-5 w-5" />
                  <span>50,000+ Happy Customers</span>
                </div>
              </div>
            </div>
            <div className="relative">
              <div className="w-full h-96 bg-white/10 rounded-lg backdrop-blur-sm flex items-center justify-center">
                <span className="text-8xl">🛒</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-16 bg-muted/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature, index) => (
              <Card key={index} className="text-center">
                <CardContent className="p-6">
                  <div className="mx-auto w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mb-4">
                    <feature.icon className="h-6 w-6 text-primary" />
                  </div>
                  <h3 className="font-semibold mb-2">{feature.title}</h3>
                  <p className="text-sm text-muted-foreground">{feature.description}</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* Categories Section */}
      <section className="py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold mb-4">Shop by Categories</h2>
            <p className="text-muted-foreground max-w-2xl mx-auto">
              Explore our wide range of categories and find exactly what you're looking for
            </p>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-8 gap-4">
            {categories.map((category, index) => (
              <Link
                key={index}
                href={`/categories/${category.name.toLowerCase().replace(' & ', '-').replace(' ', '-')}`}
                className="group"
              >
                <Card className="hover:shadow-lg transition-shadow text-center">
                  <CardContent className="p-6">
                    <div className={`w-12 h-12 ${category.color} rounded-full flex items-center justify-center mx-auto mb-3 text-2xl`}>
                      {category.icon}
                    </div>
                    <h3 className="font-medium text-sm mb-1">{category.name}</h3>
                    <p className="text-xs text-muted-foreground">{category.count} items</p>
                  </CardContent>
                </Card>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Featured Products Section */}
      <section className="py-16 bg-muted/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center mb-8">
            <div>
              <h2 className="text-3xl font-bold mb-2">Featured Products</h2>
              <p className="text-muted-foreground">Handpicked products from our trusted vendors</p>
            </div>
            <Button variant="outline" asChild>
              <Link href="/products?featured=true">
                View All
                <ArrowRight className="ml-2 h-4 w-4" />
              </Link>
            </Button>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {(featuredProducts.length > 0 ? featuredProducts : mockFeaturedProducts).slice(0, 8).map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        </div>
      </section>

      {/* Sale Products Section */}
      <section className="py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center mb-8">
            <div>
              <h2 className="text-3xl font-bold mb-2">Limited Time Deals</h2>
              <p className="text-muted-foreground">Don't miss out on these amazing discounts</p>
            </div>
            <Button variant="outline" asChild>
              <Link href="/deals">
                View All Deals
                <ArrowRight className="ml-2 h-4 w-4" />
              </Link>
            </Button>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {(onSaleProducts.length > 0 ? onSaleProducts : mockFeaturedProducts).slice(0, 8).map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        </div>
      </section>

      {/* Newsletter Section */}
      <section className="py-16 bg-primary text-primary-foreground">
        <div className="max-w-4xl mx-auto text-center px-4 sm:px-6 lg:px-8">
          <h2 className="text-3xl font-bold mb-4">Stay in the Loop</h2>
          <p className="text-primary-foreground/90 mb-8 text-lg">
            Get the latest updates on new products, exclusive deals, and vendor highlights
          </p>
          <div className="flex flex-col sm:flex-row gap-4 max-w-md mx-auto">
            <input
              type="email"
              placeholder="Enter your email"
              className="flex-1 px-4 py-3 rounded-md text-foreground"
            />
            <Button size="lg" variant="premium">
              Subscribe
              <ArrowRight className="ml-2 h-4 w-4" />
            </Button>
          </div>
          <p className="text-sm text-primary-foreground/70 mt-4">
            No spam, unsubscribe anytime
          </p>
        </div>
      </section>
    </div>
  )
}
