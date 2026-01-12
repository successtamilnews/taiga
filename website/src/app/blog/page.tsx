"use client"

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { contentService } from '@/services/content'

export default function BlogPage() {
  const [posts, setPosts] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const run = async () => {
      setLoading(true)
      try {
        const res = await contentService.getPosts(1)
        const list = Array.isArray((res as any)?.data) ? (res as any)?.data : (res as any)?.data?.data || []
        setPosts(list)
      } finally {
        setLoading(false)
      }
    }
    run()
  }, [])

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h1 className="text-3xl font-bold mb-6">Blog</h1>
        {loading ? (
          <div className="space-y-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-24 bg-muted rounded animate-pulse" />
            ))}
          </div>
        ) : posts.length === 0 ? (
          <div className="text-muted-foreground">No posts available.</div>
        ) : (
          <div className="space-y-6">
            {posts.map((post, idx) => (
              <div key={idx} className="border rounded p-4">
                <h3 className="font-semibold">{post.title || 'Untitled'}</h3>
                <p className="text-sm text-muted-foreground">{post.author || 'Team'} • {post.published_at || 'Recently'}</p>
                <p className="mt-2">{post.excerpt || 'Read more in full article.'}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
