import axios, { AxiosInstance, AxiosResponse } from 'axios';

const BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

class ApiService {
  private api: AxiosInstance;

  constructor() {
    this.api = axios.create({
      baseURL: BASE_URL,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor
    this.api.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('pos_token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Response interceptor
    this.api.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          localStorage.removeItem('pos_token');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  setAuthToken(token: string | null) {
    if (token) {
      this.api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    } else {
      delete this.api.defaults.headers.common['Authorization'];
    }
  }

  async get(url: string, params?: any): Promise<AxiosResponse> {
    return this.api.get(url, { params });
  }

  async post(url: string, data?: any): Promise<AxiosResponse> {
    return this.api.post(url, data);
  }

  async put(url: string, data?: any): Promise<AxiosResponse> {
    return this.api.put(url, data);
  }

  async delete(url: string): Promise<AxiosResponse> {
    return this.api.delete(url);
  }

  // Product methods
  async getProducts(params?: any) {
    return this.get('/products', params);
  }

  async createProduct(productData: any) {
    return this.post('/products', productData);
  }

  async updateProduct(id: number, productData: any) {
    return this.put(`/products/${id}`, productData);
  }

  async deleteProduct(id: number) {
    return this.delete(`/products/${id}`);
  }

  // Order methods
  async createOrder(orderData: any) {
    return this.post('/orders', orderData);
  }

  async getOrders(params?: any) {
    return this.get('/orders', params);
  }

  async updateOrderStatus(id: number, status: string) {
    return this.put(`/orders/${id}/status`, { status });
  }

  // Payment methods
  async processPayment(paymentData: any) {
    return this.post('/payments/process', paymentData);
  }

  // Inventory methods
  async getInventory(params?: any) {
    return this.get('/inventory', params);
  }

  async updateStock(productId: number, quantity: number) {
    return this.put(`/inventory/${productId}`, { quantity });
  }

  // Reports methods
  async getDashboardStats() {
    return this.get('/reports/dashboard');
  }

  async getSalesReport(params: any) {
    return this.get('/reports/sales', params);
  }

  async getInventoryReport() {
    return this.get('/reports/inventory');
  }

  // Categories methods
  async getCategories() {
    return this.get('/categories');
  }

  // Customer methods
  async searchCustomers(query: string) {
    return this.get('/customers/search', { q: query });
  }

  async createCustomer(customerData: any) {
    return this.post('/customers', customerData);
  }
}

export const apiService = new ApiService();