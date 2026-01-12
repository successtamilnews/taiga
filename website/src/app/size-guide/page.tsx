"use client"

import { useEffect, useState } from 'react'
import { contentService } from '@/services/content'

export default function SizeGuidePage() {
  const [guide, setGuide] = useState<any | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const run = async () => {
      setLoading(true)
      try {
        const res = await contentService.getSizeGuide()
        const data = (res as any)?.data || (res as any)?.data?.data || null
        setGuide(data)
      } finally {
        setLoading(false)
      }
    }
    run()
  }, [])

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h1 className="text-3xl font-bold mb-6">Size Guide</h1>
        {loading ? (
          <div className="space-y-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-6 bg-muted rounded animate-pulse" />
            ))}
          </div>
        ) : (
          <div className="prose max-w-none">
            <p>{guide?.content || 'Our comprehensive size guide will be available soon.'}</p>
          </div>
        )}
      </div>
    </div>
  )
}
