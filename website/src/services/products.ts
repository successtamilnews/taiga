import { apiClient } from './api'
import { Product, ApiResponse, SearchFilters } from '@/types'

export const productService = {
  // Get all products with filters
  async getProducts(filters?: SearchFilters & { page?: number; per_page?: number }): Promise<ApiResponse<Product[]>> {
    return await apiClient.get('/api/v1/products', filters)
  },

  // Get a single product by slug
  async getProduct(slug: string): Promise<ApiResponse<Product>> {
    return await apiClient.get(`/api/v1/products/${slug}`)
  },

  // Get featured products
  async getFeaturedProducts(limit?: number): Promise<ApiResponse<Product[]>> {
    return await apiClient.get('/api/v1/products/featured', { limit })
  },

  // Get products on sale
  async getProductsOnSale(limit?: number): Promise<ApiResponse<Product[]>> {
    // Assuming V1 controller supports filtering; fallback to general list with featured/on-sale flags
    return await apiClient.get('/api/v1/products', { on_sale: true, limit })
  },

  // Get newest products
  async getNewestProducts(limit?: number): Promise<ApiResponse<Product[]>> {
    return await apiClient.get('/api/v1/products', { sort: 'newest', limit })
  },

  // Get products by category
  async getProductsByCategory(categorySlug: string, filters?: SearchFilters): Promise<ApiResponse<Product[]>> {
    return await apiClient.get(`/api/v1/categories/${categorySlug}/products`, filters)
  },

  // Get products by vendor
  async getProductsByVendor(vendorSlug: string, filters?: SearchFilters): Promise<ApiResponse<Product[]>> {
    return await apiClient.get(`/api/v1/vendors/${vendorSlug}/products`, filters)
  },

  // Search products
  async searchProducts(query: string, filters?: SearchFilters): Promise<ApiResponse<Product[]>> {
    return await apiClient.get('/api/v1/products', { q: query, ...filters })
  },

  // Get related products
  async getRelatedProducts(productId: string, limit?: number): Promise<ApiResponse<Product[]>> {
    return await apiClient.get(`/api/v1/products/${productId}/related`, { limit })
  },

  // Get product reviews
  async getProductReviews(productId: string, page?: number): Promise<ApiResponse<any[]>> {
    return await apiClient.get(`/api/v1/products/${productId}/reviews`, { page })
  },

  // Add product review
  async addProductReview(productId: string, reviewData: any): Promise<ApiResponse<any>> {
    return await apiClient.post(`/api/products/${productId}/reviews`, reviewData)
  },

  // Get product variations
  async getProductVariations(productId: string): Promise<ApiResponse<any[]>> {
    return await apiClient.get(`/api/products/${productId}/variations`)
  }
}