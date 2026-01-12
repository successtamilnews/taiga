"use client"

import { useEffect, useState } from 'react'
import { contentService } from '@/services/content'

export default function CareersPage() {
  const [jobs, setJobs] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const run = async () => {
      setLoading(true)
      try {
        const res = await contentService.getJobs()
        const list = Array.isArray((res as any)?.data) ? (res as any)?.data : (res as any)?.data?.data || []
        setJobs(list)
      } finally {
        setLoading(false)
      }
    }
    run()
  }, [])

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h1 className="text-3xl font-bold mb-6">Careers</h1>
        <p className="text-muted-foreground mb-6">Join our mission to build a world-class multi-vendor platform.</p>
        {loading ? (
          <div className="space-y-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-20 bg-muted rounded animate-pulse" />
            ))}
          </div>
        ) : jobs.length === 0 ? (
          <div className="text-muted-foreground">No open positions currently.</div>
        ) : (
          <div className="space-y-4">
            {jobs.map((job, idx) => (
              <div key={idx} className="border rounded p-4">
                <h3 className="font-semibold">{job.title || 'Role'}</h3>
                <p className="text-sm text-muted-foreground">{job.location || 'Remote'}</p>
                <p className="mt-2">{job.description || 'Details available upon request.'}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
