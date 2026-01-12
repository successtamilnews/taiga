'use client'

import Link from 'next/link'
import { useState } from 'react'
import { 
  Search, 
  ShoppingCart, 
  User, 
  Heart, 
  Menu, 
  X,
  MapPin,
  Phone,
  Mail
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useCartStore } from '@/store/cart'
import { useAuthStore } from '@/store/auth'
import { useAppStore } from '@/store/app'

const LANG_OPTIONS = [
  { code: 'en', name: 'English', flag: '🇺🇸', dir: 'ltr' as const },
  { code: 'si', name: 'Sinhala', flag: '🇱🇰', dir: 'ltr' as const },
  { code: 'ta', name: 'Tamil', flag: '🇱🇰', dir: 'ltr' as const },
]

const CURR_OPTIONS = [
  { code: 'LKR', name: 'Sri Lankan Rupee', symbol: 'Rs.', rate: 1 },
  { code: 'USD', name: 'US Dollar', symbol: '$', rate: 0.0032 },
]

export function Header() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [isSearchOpen, setIsSearchOpen] = useState(false)
  
  const { getItemCount } = useCartStore()
  const { isAuthenticated, user } = useAuthStore()
  const { searchQuery, setSearchQuery, language, currency, setLanguage, setCurrency } = useAppStore()

  const cartItemCount = getItemCount()

  return (
    <header className="sticky top-0 z-50 w-full bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      {/* Top Bar */}
      <div className="hidden md:block bg-primary text-primary-foreground py-2">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center space-x-6">
              <div className="flex items-center space-x-2">
                <Phone className="h-4 w-4" />
                <span>+94 11 123 4567</span>
              </div>
              <div className="flex items-center space-x-2">
                <Mail className="h-4 w-4" />
                <span>support@taiga.asia</span>
              </div>
              <div className="flex items-center space-x-2">
                <MapPin className="h-4 w-4" />
                <span>Free delivery island wide</span>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              {/* Language & Currency (top bar) */}
              <div className="hidden md:flex items-center space-x-3 text-sm">
                <select
                  value={language.code}
                  onChange={(e) => {
                    const opt = LANG_OPTIONS.find(l => l.code === e.target.value) || LANG_OPTIONS[0]
                    setLanguage(opt)
                  }}
                  className="bg-transparent border border-primary-foreground/30 rounded px-2 py-1"
                  aria-label="Select language"
                >
                  {LANG_OPTIONS.map(l => (
                    <option key={l.code} value={l.code}>{l.flag} {l.name}</option>
                  ))}
                </select>

                <select
                  value={currency.code}
                  onChange={(e) => {
                    const opt = CURR_OPTIONS.find(c => c.code === e.target.value) || CURR_OPTIONS[0]
                    setCurrency(opt)
                  }}
                  className="bg-transparent border border-primary-foreground/30 rounded px-2 py-1"
                  aria-label="Select currency"
                >
                  {CURR_OPTIONS.map(c => (
                    <option key={c.code} value={c.code}>{c.symbol} {c.code}</option>
                  ))}
                </select>
              </div>

              <Link href="/track-order" className="hover:underline">
                Track Order
              </Link>
              <Link href="/help" className="hover:underline">
                Help & Support
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Main Header */}
      <div className="border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <Link href="/" className="flex items-center space-x-2">
              <div className="bg-primary text-primary-foreground w-10 h-10 rounded-lg flex items-center justify-center font-bold text-xl">
                T
              </div>
              <span className="text-2xl font-bold gradient-text">Taiga</span>
            </Link>

            {/* Navigation */}
            <nav className="hidden md:flex items-center space-x-8">
              <Link 
                href="/" 
                className="text-foreground hover:text-primary transition-colors"
              >
                Home
              </Link>
              <Link 
                href="/products" 
                className="text-foreground hover:text-primary transition-colors"
              >
                Products
              </Link>
              <Link 
                href="/categories" 
                className="text-foreground hover:text-primary transition-colors"
              >
                Categories
              </Link>
              <Link 
                href="/vendors" 
                className="text-foreground hover:text-primary transition-colors"
              >
                Vendors
              </Link>
              <Link 
                href="/deals" 
                className="text-foreground hover:text-primary transition-colors"
              >
                Deals
              </Link>
              <Link 
                href="/about" 
                className="text-foreground hover:text-primary transition-colors"
              >
                About
              </Link>
            </nav>

            {/* Search icon toggle (replaces desktop search bar) */}
            <div className="flex-1 mx-8 hidden" />

            {/* Actions */}
            <div className="flex items-center space-x-4">
              {/* Search toggle */}
              <Button
                variant="ghost"
                size="icon"
                onClick={() => setIsSearchOpen(!isSearchOpen)}
              >
                <Search className="h-5 w-5" />
              </Button>

              {/* Wishlist */}
              <Button variant="ghost" size="icon" asChild>
                <Link href="/wishlist">
                  <Heart className="h-5 w-5" />
                </Link>
              </Button>

              {/* Cart */}
              <Button variant="ghost" size="icon" className="relative" asChild>
                <Link href="/cart">
                  <ShoppingCart className="h-5 w-5" />
                  {cartItemCount > 0 && (
                    <span className="absolute -top-1 -right-1 bg-primary text-primary-foreground text-xs rounded-full h-5 w-5 flex items-center justify-center">
                      {cartItemCount}
                    </span>
                  )}
                </Link>
              </Button>

              {/* User Menu */}
              {isAuthenticated ? (
                <Button variant="ghost" size="icon" asChild>
                  <Link href="/profile">
                    <User className="h-5 w-5" />
                  </Link>
                </Button>
              ) : (
                <Button asChild>
                  <Link href="/auth/login">Login</Link>
                </Button>
              )}

              {/* Mobile Menu */}
              <Button
                variant="ghost"
                size="icon"
                className="md:hidden"
                onClick={() => setIsMenuOpen(!isMenuOpen)}
              >
                {isMenuOpen ? (
                  <X className="h-5 w-5" />
                ) : (
                  <Menu className="h-5 w-5" />
                )}
              </Button>
            </div>
          </div>
        </div>

        {/* Search Bar (shown when toggled) */}
        {isSearchOpen && (
          <div className="border-t px-4 py-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
              <Input
                type="text"
                placeholder="Search products..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10 pr-4"
              />
            </div>
          </div>
        )}

        {/* Mobile Navigation */}
        {isMenuOpen && (
          <div className="md:hidden border-t">
            <div className="px-4 py-6 space-y-4">
              <Link 
                href="/" 
                className="block text-foreground hover:text-primary transition-colors"
                onClick={() => setIsMenuOpen(false)}
              >
                Home
              </Link>
              <Link 
                href="/products" 
                className="block text-foreground hover:text-primary transition-colors"
                onClick={() => setIsMenuOpen(false)}
              >
                Products
              </Link>
              <Link 
                href="/categories" 
                className="block text-foreground hover:text-primary transition-colors"
                onClick={() => setIsMenuOpen(false)}
              >
                Categories
              </Link>
              <Link 
                href="/vendors" 
                className="block text-foreground hover:text-primary transition-colors"
                onClick={() => setIsMenuOpen(false)}
              >
                Vendors
              </Link>
              <Link 
                href="/deals" 
                className="block text-foreground hover:text-primary transition-colors"
                onClick={() => setIsMenuOpen(false)}
              >
                Deals
              </Link>
              <Link 
                href="/about" 
                className="block text-foreground hover:text-primary transition-colors"
                onClick={() => setIsMenuOpen(false)}
              >
                About
              </Link>
              {!isAuthenticated && (
                <div className="pt-4">
                  <Button asChild className="w-full">
                    <Link href="/auth/login" onClick={() => setIsMenuOpen(false)}>
                      Login
                    </Link>
                  </Button>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </header>
  )
}