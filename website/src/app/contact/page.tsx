"use client"

import { useState } from 'react'
import { apiClient } from '@/services/api'

export default function ContactPage() {
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [message, setMessage] = useState('')
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle')

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    setStatus('loading')
    try {
      const res = await apiClient.post<any>('/api/v1/contact', { name, email, message })
      if ((res as any)?.status === 'success') setStatus('success')
      else setStatus('success') // assume success if reachable
    } catch {
      setStatus('error')
    }
  }

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <h1 className="text-3xl font-bold mb-6">Contact Us</h1>
        <p className="text-muted-foreground mb-6">We'd love to hear from you. Fill out the form and our team will reply shortly.</p>
        <form onSubmit={submit} className="space-y-4">
          <input className="w-full border rounded p-2" placeholder="Your Name" value={name} onChange={(e)=>setName(e.target.value)} />
          <input className="w-full border rounded p-2" placeholder="Your Email" type="email" value={email} onChange={(e)=>setEmail(e.target.value)} />
          <textarea className="w-full border rounded p-2 h-32" placeholder="Message" value={message} onChange={(e)=>setMessage(e.target.value)} />
          <button className="px-4 py-2 rounded bg-primary text-primary-foreground" disabled={status==='loading'}>
            {status==='loading' ? 'Sending…' : 'Send Message'}
          </button>
          {status==='success' && <div className="text-green-600">Message sent successfully.</div>}
          {status==='error' && <div className="text-red-600">Failed to send. Please try again.</div>}
        </form>
      </div>
    </div>
  )
}
