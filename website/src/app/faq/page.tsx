"use client"

import { useEffect, useState } from 'react'
import { contentService } from '@/services/content'

export default function FAQPage() {
  const [faqs, setFaqs] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const run = async () => {
      setLoading(true)
      try {
        const res = await contentService.getFaqs()
        const list = Array.isArray((res as any)?.data) ? (res as any)?.data : (res as any)?.data?.data || []
        setFaqs(list)
      } finally {
        setLoading(false)
      }
    }
    run()
  }, [])

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h1 className="text-3xl font-bold mb-6">Frequently Asked Questions</h1>
        {loading ? (
          <div className="space-y-4">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-6 bg-muted rounded animate-pulse" />
            ))}
          </div>
        ) : faqs.length === 0 ? (
          <div className="text-muted-foreground">No FAQs available yet.</div>
        ) : (
          <div className="space-y-4">
            {faqs.map((faq, idx) => (
              <div key={idx} className="border rounded p-4">
                <h3 className="font-semibold">{faq.question || 'Question'}</h3>
                <p className="mt-2">{faq.answer || 'Answer will be available soon.'}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
