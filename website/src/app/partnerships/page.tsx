export default function PartnershipsPage() {
  return (
    <main className="min-h-screen bg-muted/30">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <h1 className="text-3xl font-bold mb-4">Partnerships</h1>
        <p className="text-muted-foreground mb-6">
          Partner with Taiga to reach more customers across Sri Lanka. We support vendors, logistics providers, and service partners.
        </p>
        <div className="space-y-4">
          <section>
            <h2 className="text-xl font-semibold mb-2">Become a Vendor</h2>
            <p className="text-sm text-muted-foreground">List your products and manage orders with our vendor tools.</p>
          </section>
          <section>
            <h2 className="text-xl font-semibold mb-2">Logistics Partners</h2>
            <p className="text-sm text-muted-foreground">Work with us to offer reliable delivery across the island.</p>
          </section>
          <section>
            <h2 className="text-xl font-semibold mb-2">Payment Partners</h2>
            <p className="text-sm text-muted-foreground">Join our payment ecosystem (Google Pay, Apple Pay, Sampath Bank).</p>
          </section>
        </div>
        <div className="mt-8">
          <a href="mailto:partners@taiga.lk" className="underline">Email partners@taiga.asia</a>
        </div>
      </div>
    </main>
  )
}
