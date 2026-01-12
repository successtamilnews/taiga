import axios, { AxiosInstance, AxiosResponse } from 'axios'
import { ApiResponse } from '@/types'

class ApiClient {
  private client: AxiosInstance

  constructor() {
    this.client = axios.create({
      baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      timeout: 30000,
    })

    this.setupInterceptors()
  }

  private setupInterceptors() {
    // Request interceptor
    this.client.interceptors.request.use(
      (config) => {
        // Add auth token if available
        if (typeof window !== 'undefined') {
          const token = localStorage.getItem('taiga-auth-storage')
          if (token) {
            try {
              const parsed = JSON.parse(token)
              if (parsed.state?.token) {
                config.headers.Authorization = `Bearer ${parsed.state.token}`
              }
            } catch (error) {
              console.error('Error parsing auth token:', error)
            }
          }
        }

        return config
      },
      (error) => {
        return Promise.reject(error)
      }
    )

    // Response interceptor
    this.client.interceptors.response.use(
      (response: AxiosResponse<ApiResponse>) => {
        return response
      },
      (error) => {
        if (error.response?.status === 401) {
          // Handle unauthorized access
          if (typeof window !== 'undefined') {
            localStorage.removeItem('taiga-auth-storage')
            window.location.href = '/auth/login'
          }
        }

        // Transform error response
        const errorMessage = error.response?.data?.message || 
                           error.response?.data?.error || 
                           error.message || 
                           'An unexpected error occurred'

        return Promise.reject({
          message: errorMessage,
          status: error.response?.status,
          data: error.response?.data
        })
      }
    )
  }

  // Generic HTTP methods
  async get<T = any>(url: string, params?: any): Promise<ApiResponse<T>> {
    try {
      const response = await this.client.get(url, { params })
      return response.data
    } catch (error: any) {
      return {
        success: false,
        message: error?.message || 'Request failed',
      }
    }
  }

  async post<T = any>(url: string, data?: any): Promise<ApiResponse<T>> {
    try {
      const response = await this.client.post(url, data)
      return response.data
    } catch (error: any) {
      return {
        success: false,
        message: error?.message || 'Request failed',
      }
    }
  }

  async put<T = any>(url: string, data?: any): Promise<ApiResponse<T>> {
    try {
      const response = await this.client.put(url, data)
      return response.data
    } catch (error: any) {
      return {
        success: false,
        message: error?.message || 'Request failed',
      }
    }
  }

  async patch<T = any>(url: string, data?: any): Promise<ApiResponse<T>> {
    try {
      const response = await this.client.patch(url, data)
      return response.data
    } catch (error: any) {
      return {
        success: false,
        message: error?.message || 'Request failed',
      }
    }
  }

  async delete<T = any>(url: string): Promise<ApiResponse<T>> {
    try {
      const response = await this.client.delete(url)
      return response.data
    } catch (error: any) {
      return {
        success: false,
        message: error?.message || 'Request failed',
      }
    }
  }

  // File upload method
  async upload<T = any>(url: string, file: File, onProgress?: (progress: number) => void): Promise<ApiResponse<T>> {
    const formData = new FormData()
    formData.append('file', file)

    try {
      const response = await this.client.post(url, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        },
        onUploadProgress: (progressEvent) => {
          if (onProgress && progressEvent.total) {
            const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total)
            onProgress(progress)
          }
        }
      })

      return response.data
    } catch (error: any) {
      return {
        success: false,
        message: error?.message || 'Upload failed',
      }
    }
  }
}

export const apiClient = new ApiClient()