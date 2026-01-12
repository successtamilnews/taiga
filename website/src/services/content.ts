import { apiClient } from '@/services/api'

export const contentService = {
  async getPage(slug: string) {
    return apiClient.get<any>('/api/v1/pages', { slug })
  },
  async getFaqs() {
    return apiClient.get<any>('/api/v1/faqs')
  },
  async getPosts(page: number = 1) {
    return apiClient.get<any>('/api/v1/posts', { page, per_page: 12 })
  },
  async getJobs() {
    return apiClient.get<any>('/api/v1/jobs')
  },
  async getPress(page: number = 1) {
    return apiClient.get<any>('/api/v1/press', { page, per_page: 12 })
  },
  async trackOrder(number: string) {
    return apiClient.get<any>('/api/v1/orders/track', { number })
  },
  async getPolicy(slug: string) {
    return apiClient.get<any>('/api/v1/policies', { slug })
  },
  async getSizeGuide() {
    return apiClient.get<any>('/api/v1/size-guide')
  },
  async getHelp() {
    return apiClient.get<any>('/api/v1/help')
  },
}
