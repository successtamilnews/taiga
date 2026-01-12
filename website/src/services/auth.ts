import { apiClient } from './api'
import { User, ApiResponse } from '@/types'

export interface LoginCredentials {
  email: string
  password: string
  remember?: boolean
}

export interface RegisterData {
  name: string
  email: string
  password: string
  password_confirmation: string
  phone?: string
}

export interface ForgotPasswordData {
  email: string
}

export interface ResetPasswordData {
  email: string
  token: string
  password: string
  password_confirmation: string
}

export interface AuthResponse {
  user: User
  token: string
  expires_in: number
}

export const authService = {
  // User registration
  async register(data: RegisterData): Promise<ApiResponse<AuthResponse>> {
    return await apiClient.post('/api/auth/register', data)
  },

  // User login
  async login(credentials: LoginCredentials): Promise<ApiResponse<AuthResponse>> {
    return await apiClient.post('/api/auth/login', credentials)
  },

  // User logout
  async logout(): Promise<ApiResponse<any>> {
    return await apiClient.post('/api/auth/logout')
  },

  // Get current user profile
  async getProfile(): Promise<ApiResponse<User>> {
    return await apiClient.get('/api/auth/profile')
  },

  // Update user profile
  async updateProfile(data: Partial<User>): Promise<ApiResponse<User>> {
    return await apiClient.put('/api/auth/profile', data)
  },

  // Change password
  async changePassword(data: { current_password: string; password: string; password_confirmation: string }): Promise<ApiResponse<any>> {
    return await apiClient.post('/api/auth/change-password', data)
  },

  // Forgot password
  async forgotPassword(data: ForgotPasswordData): Promise<ApiResponse<any>> {
    return await apiClient.post('/api/auth/forgot-password', data)
  },

  // Reset password
  async resetPassword(data: ResetPasswordData): Promise<ApiResponse<any>> {
    return await apiClient.post('/api/auth/reset-password', data)
  },

  // Verify email
  async verifyEmail(token: string): Promise<ApiResponse<any>> {
    return await apiClient.post('/api/auth/verify-email', { token })
  },

  // Resend verification email
  async resendVerification(): Promise<ApiResponse<any>> {
    return await apiClient.post('/api/auth/resend-verification')
  },

  // Refresh token
  async refreshToken(): Promise<ApiResponse<AuthResponse>> {
    return await apiClient.post('/api/auth/refresh')
  },

  // Check if email exists
  async checkEmail(email: string): Promise<ApiResponse<{ exists: boolean }>> {
    return await apiClient.post('/api/auth/check-email', { email })
  },

  // Social login (Google, Facebook, etc.)
  async socialLogin(provider: string, token: string): Promise<ApiResponse<AuthResponse>> {
    return await apiClient.post(`/api/auth/social/${provider}`, { token })
  }
}