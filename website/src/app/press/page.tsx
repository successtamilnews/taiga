"use client"

import { useEffect, useState } from 'react'
import { contentService } from '@/services/content'

export default function PressPage() {
  const [items, setItems] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const run = async () => {
      setLoading(true)
      try {
        const res = await contentService.getPress(1)
        const list = Array.isArray((res as any)?.data) ? (res as any)?.data : (res as any)?.data?.data || []
        setItems(list)
      } finally {
        setLoading(false)
      }
    }
    run()
  }, [])

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h1 className="text-3xl font-bold mb-6">Press</h1>
        {loading ? (
          <div className="space-y-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-24 bg-muted rounded animate-pulse" />
            ))}
          </div>
        ) : items.length === 0 ? (
          <div className="text-muted-foreground">No press releases yet.</div>
        ) : (
          <div className="space-y-6">
            {items.map((item, idx) => (
              <div key={idx} className="border rounded p-4">
                <h3 className="font-semibold">{item.title || 'Update'}</h3>
                <p className="text-sm text-muted-foreground">{item.published_at || 'Recently'}</p>
                <p className="mt-2">{item.excerpt || 'Details available.'}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
