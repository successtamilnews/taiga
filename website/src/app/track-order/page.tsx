"use client"

import { useState } from 'react'
import { contentService } from '@/services/content'

export default function TrackOrderPage() {
  const [number, setNumber] = useState('')
  const [result, setResult] = useState<any | null>(null)
  const [loading, setLoading] = useState(false)

  const track = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      const res = await contentService.trackOrder(number)
      const data = (res as any)?.data || (res as any)?.data?.data || null
      setResult(data)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h1 className="text-3xl font-bold mb-6">Track Order</h1>
        <form onSubmit={track} className="flex gap-2 mb-6">
          <input className="flex-1 border rounded p-2" placeholder="Enter order number" value={number} onChange={(e)=>setNumber(e.target.value)} />
          <button className="px-4 py-2 rounded bg-primary text-primary-foreground" disabled={loading || !number}>
            {loading ? 'Checking…' : 'Track'}
          </button>
        </form>
        {result ? (
          <div className="border rounded p-4">
            <p><span className="font-semibold">Status:</span> {result.status || 'Unknown'}</p>
            <p><span className="font-semibold">Estimated Delivery:</span> {result.eta || '—'}</p>
            <p><span className="font-semibold">Last Update:</span> {result.updated_at || '—'}</p>
          </div>
        ) : (
          <p className="text-muted-foreground">Enter your order number to see updates.</p>
        )}
      </div>
    </div>
  )
}
