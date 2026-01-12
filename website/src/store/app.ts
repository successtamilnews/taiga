import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { Currency, Language } from '@/types'

interface AppStore {
  currency: Currency
  language: Language
  isLoading: boolean
  searchQuery: string
  recentSearches: string[]
  wishlist: string[]
  notifications: any[]
  setCurrency: (currency: Currency) => void
  setLanguage: (language: Language) => void
  setLoading: (loading: boolean) => void
  setSearchQuery: (query: string) => void
  addRecentSearch: (query: string) => void
  clearRecentSearches: () => void
  addToWishlist: (productId: string) => void
  removeFromWishlist: (productId: string) => void
  isInWishlist: (productId: string) => boolean
  addNotification: (notification: any) => void
  removeNotification: (id: string) => void
  clearNotifications: () => void
}

const defaultCurrency: Currency = {
  code: 'LKR',
  name: 'Sri Lankan Rupee',
  symbol: 'Rs.',
  rate: 1
}

const defaultLanguage: Language = {
  code: 'en',
  name: 'English',
  flag: '🇺🇸',
  dir: 'ltr'
}

export const useAppStore = create<AppStore>()(
  persist(
    (set, get) => ({
      currency: defaultCurrency,
      language: defaultLanguage,
      isLoading: false,
      searchQuery: '',
      recentSearches: [],
      wishlist: [],
      notifications: [],

      setCurrency: (currency) => {
        set({ currency })
      },

      setLanguage: (language) => {
        set({ language })
        // Update document direction
        if (typeof document !== 'undefined') {
          document.documentElement.dir = language.dir
        }
      },

      setLoading: (loading) => {
        set({ isLoading: loading })
      },

      setSearchQuery: (query) => {
        set({ searchQuery: query })
      },

      addRecentSearch: (query) => {
        if (!query.trim()) return
        
        const { recentSearches } = get()
        const filtered = recentSearches.filter(search => search !== query)
        const newSearches = [query, ...filtered].slice(0, 10) // Keep only 10 recent searches
        
        set({ recentSearches: newSearches })
      },

      clearRecentSearches: () => {
        set({ recentSearches: [] })
      },

      addToWishlist: (productId) => {
        const { wishlist } = get()
        if (!wishlist.includes(productId)) {
          set({ wishlist: [...wishlist, productId] })
        }
      },

      removeFromWishlist: (productId) => {
        const { wishlist } = get()
        set({ wishlist: wishlist.filter(id => id !== productId) })
      },

      isInWishlist: (productId) => {
        return get().wishlist.includes(productId)
      },

      addNotification: (notification) => {
        const newNotification = {
          ...notification,
          id: Date.now().toString(),
          timestamp: new Date().toISOString()
        }
        set({ notifications: [...get().notifications, newNotification] })
      },

      removeNotification: (id) => {
        set({ notifications: get().notifications.filter(n => n.id !== id) })
      },

      clearNotifications: () => {
        set({ notifications: [] })
      }
    }),
    {
      name: 'taiga-app-storage'
    }
  )
)