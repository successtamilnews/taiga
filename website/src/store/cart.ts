import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { Cart, CartItem, Product, ProductVariation, Currency, Language } from '@/types'

interface CartStore {
  cart: Cart
  addItem: (product: Product, variation?: ProductVariation, quantity?: number) => void
  updateQuantity: (itemId: string, quantity: number) => void
  removeItem: (itemId: string) => void
  clearCart: () => void
  getItemCount: () => number
  getItemById: (productId: string, variationId?: string) => CartItem | undefined
}

export const useCartStore = create<CartStore>()(
  persist(
    (set, get) => ({
      cart: {
        items: [],
        subtotal: 0,
        tax: 0,
        shipping: 0,
        discount: 0,
        total: 0,
        currency: 'LKR'
      },
      
      addItem: (product, variation, quantity = 1) => {
        const existingItem = get().getItemById(product.id, variation?.id)
        
        if (existingItem) {
          get().updateQuantity(existingItem.id, existingItem.quantity + quantity)
          return
        }

        const price = variation?.sale_price || variation?.price || product.sale_price || product.price
        const newItem: CartItem = {
          id: `${product.id}-${variation?.id || 'default'}`,
          product,
          variation,
          quantity,
          price,
          total: price * quantity
        }

        set((state) => {
          const newItems = [...state.cart.items, newItem]
          return {
            cart: {
              ...state.cart,
              items: newItems,
              ...calculateTotals(newItems)
            }
          }
        })
      },

      updateQuantity: (itemId, quantity) => {
        if (quantity <= 0) {
          get().removeItem(itemId)
          return
        }

        set((state) => {
          const newItems = state.cart.items.map(item =>
            item.id === itemId
              ? { ...item, quantity, total: item.price * quantity }
              : item
          )
          return {
            cart: {
              ...state.cart,
              items: newItems,
              ...calculateTotals(newItems)
            }
          }
        })
      },

      removeItem: (itemId) => {
        set((state) => {
          const newItems = state.cart.items.filter(item => item.id !== itemId)
          return {
            cart: {
              ...state.cart,
              items: newItems,
              ...calculateTotals(newItems)
            }
          }
        })
      },

      clearCart: () => {
        set((state) => ({
          cart: {
            ...state.cart,
            items: [],
            subtotal: 0,
            tax: 0,
            shipping: 0,
            discount: 0,
            total: 0
          }
        }))
      },

      getItemCount: () => {
        return get().cart.items.reduce((total, item) => total + item.quantity, 0)
      },

      getItemById: (productId, variationId) => {
        const itemId = `${productId}-${variationId || 'default'}`
        return get().cart.items.find(item => item.id === itemId)
      }
    }),
    {
      name: 'taiga-cart-storage'
    }
  )
)

function calculateTotals(items: CartItem[]) {
  const subtotal = items.reduce((total, item) => total + item.total, 0)
  const tax = subtotal * 0.08 // 8% tax rate
  const shipping = subtotal > 5000 ? 0 : 250 // Free shipping over 5000 LKR
  const discount = 0 // Apply discounts here
  const total = subtotal + tax + shipping - discount

  return {
    subtotal,
    tax,
    shipping,
    discount,
    total
  }
}