"use client"

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { Card, CardContent } from '@/components/ui/card'
import { apiClient } from '@/services/api'

interface PublicVendor {
  id: string | number
  business_name?: string
  name?: string
  slug?: string
  logo?: string
  city?: string
  status?: string
}

export default function VendorsPage() {
  const [vendors, setVendors] = useState<PublicVendor[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchVendors = async () => {
      setLoading(true)
      const res = await apiClient.get<any>('/api/vendors')
      const list = Array.isArray(res.data) ? res.data : (res as any)?.data?.data || []
      setVendors(list)
      setLoading(false)
    }
    fetchVendors()
  }, [])

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h1 className="text-3xl font-bold mb-6">Vendors</h1>
        {loading ? (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {Array.from({ length: 8 }).map((_, i) => (
              <div key={i} className="h-28 bg-muted rounded animate-pulse" />
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {vendors.map((v) => {
              const name = v.business_name || v.name || `Vendor ${v.id}`
              const slug = v.slug || `${name.toLowerCase().replace(/\s+/g, '-')}`
              return (
                <Link key={String(v.id)} href={`/vendors/${slug}`} className="group">
                  <Card className="hover:shadow-md transition-shadow">
                    <CardContent className="p-4 text-center">
                      <div className="text-2xl mb-2">🏬</div>
                      <div className="font-medium line-clamp-1">{name}</div>
                      {v.city && <div className="text-xs text-muted-foreground">{v.city}</div>}
                    </CardContent>
                  </Card>
                </Link>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
