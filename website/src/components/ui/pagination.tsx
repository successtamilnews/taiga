"use client"

import { Button } from '@/components/ui/button'

interface PaginationProps {
  currentPage: number
  totalPages: number
  onChange: (page: number) => void
}

export function Pagination({ currentPage, totalPages, onChange }: PaginationProps) {
  if (totalPages <= 1) return null

  const maxButtons = Math.min(5, totalPages)
  const pages = Array.from({ length: maxButtons }, (_, i) => i + 1)

  return (
    <div className="mt-8 flex justify-center">
      <div className="flex space-x-2">
        <Button
          variant="outline"
          disabled={currentPage === 1}
          onClick={() => onChange(currentPage - 1)}
        >
          Previous
        </Button>
        {pages.map((page) => (
          <Button
            key={page}
            variant={currentPage === page ? 'default' : 'outline'}
            onClick={() => onChange(page)}
          >
            {page}
          </Button>
        ))}
        <Button
          variant="outline"
          disabled={currentPage === totalPages}
          onClick={() => onChange(currentPage + 1)}
        >
          Next
        </Button>
      </div>
    </div>
  )
}
