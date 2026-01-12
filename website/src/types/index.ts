export interface User {
  id: string;
  email: string;
  name: string;
  avatar?: string;
  phone?: string;
  address?: Address;
  created_at: string;
  updated_at: string;
}

export interface Address {
  id?: string;
  street: string;
  city: string;
  state: string;
  zip_code: string;
  country: string;
  is_default?: boolean;
}

export interface Category {
  id: string;
  name: string;
  slug: string;
  description?: string;
  image?: string;
  parent_id?: string;
  children?: Category[];
  created_at: string;
  updated_at: string;
}

export interface Product {
  id: string;
  name: string;
  slug: string;
  description: string;
  short_description?: string;
  price: number;
  sale_price?: number;
  sku: string;
  stock_quantity: number;
  manage_stock: boolean;
  in_stock: boolean;
  weight?: number;
  dimensions?: {
    length: number;
    width: number;
    height: number;
  };
  featured: boolean;
  status: 'active' | 'inactive' | 'draft';
  vendor: Vendor;
  categories: Category[];
  images: ProductImage[];
  attributes: ProductAttribute[];
  variations?: ProductVariation[];
  reviews: Review[];
  average_rating: number;
  total_reviews: number;
  tags: string[];
  meta: {
    title?: string;
    description?: string;
    keywords?: string;
  };
  created_at: string;
  updated_at: string;
}

export interface ProductImage {
  id: string;
  url: string;
  alt: string;
  is_primary: boolean;
  sort_order: number;
}

export interface ProductAttribute {
  id: string;
  name: string;
  value: string;
  type: 'text' | 'number' | 'boolean' | 'color' | 'size';
}

export interface ProductVariation {
  id: string;
  name: string;
  price: number;
  sale_price?: number;
  sku: string;
  stock_quantity: number;
  attributes: ProductAttribute[];
  image?: ProductImage;
}

export interface Vendor {
  id: string;
  name: string;
  slug: string;
  email: string;
  phone?: string;
  description?: string;
  logo?: string;
  cover_image?: string;
  address?: Address;
  rating: number;
  total_reviews: number;
  total_products: number;
  status: 'active' | 'inactive' | 'pending';
  social_links?: {
    facebook?: string;
    twitter?: string;
    instagram?: string;
    website?: string;
  };
  created_at: string;
  updated_at: string;
}

export interface Review {
  id: string;
  user: User;
  product: Product;
  rating: number;
  title?: string;
  comment: string;
  verified_purchase: boolean;
  helpful_count: number;
  status: 'approved' | 'pending' | 'rejected';
  created_at: string;
  updated_at: string;
}

export interface CartItem {
  id: string;
  product: Product;
  variation?: ProductVariation;
  quantity: number;
  price: number;
  total: number;
}

export interface Cart {
  items: CartItem[];
  subtotal: number;
  tax: number;
  shipping: number;
  discount: number;
  total: number;
  currency: string;
}

export interface Order {
  id: string;
  order_number: string;
  user: User;
  items: OrderItem[];
  status: OrderStatus;
  payment_status: PaymentStatus;
  shipping_status: ShippingStatus;
  billing_address: Address;
  shipping_address: Address;
  payment_method: string;
  payment_details?: any;
  subtotal: number;
  tax: number;
  shipping: number;
  discount: number;
  total: number;
  currency: string;
  notes?: string;
  tracking_number?: string;
  estimated_delivery?: string;
  created_at: string;
  updated_at: string;
}

export interface OrderItem {
  id: string;
  product: Product;
  variation?: ProductVariation;
  quantity: number;
  price: number;
  total: number;
}

export type OrderStatus = 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled' | 'refunded';
export type PaymentStatus = 'pending' | 'paid' | 'failed' | 'refunded' | 'partial';
export type ShippingStatus = 'pending' | 'processing' | 'shipped' | 'in_transit' | 'delivered' | 'returned';

export interface Currency {
  code: string;
  name: string;
  symbol: string;
  rate: number;
}

export interface Language {
  code: string;
  name: string;
  flag: string;
  dir: 'ltr' | 'rtl';
}

export interface PaymentMethod {
  id: string;
  name: string;
  type: 'google_pay' | 'apple_pay' | 'sampath_bank' | 'credit_card' | 'bank_transfer' | 'cash_on_delivery';
  enabled: boolean;
  config: any;
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  errors?: any;
  meta?: {
    total: number;
    per_page: number;
    current_page: number;
    last_page: number;
    from: number;
    to: number;
  };
}

export interface SearchFilters {
  category?: string;
  vendor?: string;
  min_price?: number;
  max_price?: number;
  in_stock?: boolean;
  featured?: boolean;
  rating?: number;
  sort?: 'name' | 'price' | 'rating' | 'newest' | 'oldest';
  order?: 'asc' | 'desc';
}