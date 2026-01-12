'use client'

export default function DemoAccountsPage() {
  const demoAccounts = [
    {
      role: 'Admin',
      email: 'admin@taiga.com',
      password: 'password',
      description: 'Full administrative access to the platform',
      color: 'bg-red-100 border-red-200 text-red-800'
    },
    {
      role: 'Vendor',
      email: 'vendor@taiga.com',
      password: 'password',
      description: 'Vendor dashboard for managing products and orders',
      color: 'bg-blue-100 border-blue-200 text-blue-800'
    },
    {
      role: 'Customer',
      email: 'customer@taiga.com',
      password: 'password',
      description: 'Customer account for shopping experience',
      color: 'bg-green-100 border-green-200 text-green-800'
    },
    {
      role: 'Delivery',
      email: 'delivery@taiga.com',
      password: 'password',
      description: 'Delivery person account for order management',
      color: 'bg-purple-100 border-purple-200 text-purple-800'
    }
  ];

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">
            🚀 Taiga Demo Accounts
          </h1>
          <p className="text-lg text-gray-600">
            Test different user roles with these pre-configured accounts
          </p>
        </div>

        <div className="grid gap-6 md:grid-cols-2">
          {demoAccounts.map((account, index) => (
            <div
              key={index}
              className={`rounded-lg border-2 p-6 ${account.color}`}
            >
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xl font-bold">{account.role}</h2>
                <span className="text-sm font-medium px-2 py-1 rounded bg-white/50">
                  Demo Account
                </span>
              </div>
              
              <p className="mb-4 text-sm">{account.description}</p>
              
              <div className="space-y-3">
                <div>
                  <label className="block text-sm font-medium mb-1">Email:</label>
                  <div className="flex items-center space-x-2">
                    <code className="flex-1 px-3 py-2 bg-white/70 rounded text-sm font-mono">
                      {account.email}
                    </code>
                    <button
                      onClick={() => copyToClipboard(account.email)}
                      className="px-3 py-2 bg-white/70 hover:bg-white/90 rounded text-sm transition-colors"
                      title="Copy email"
                    >
                      📋
                    </button>
                  </div>
                </div>
                
                <div>
                  <label className="block text-sm font-medium mb-1">Password:</label>
                  <div className="flex items-center space-x-2">
                    <code className="flex-1 px-3 py-2 bg-white/70 rounded text-sm font-mono">
                      {account.password}
                    </code>
                    <button
                      onClick={() => copyToClipboard(account.password)}
                      className="px-3 py-2 bg-white/70 hover:bg-white/90 rounded text-sm transition-colors"
                      title="Copy password"
                    >
                      📋
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-12 bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-bold mb-4">🔗 Application Links</h3>
          <div className="grid gap-4 md:grid-cols-3">
            <a
              href="http://localhost:8000"
              target="_blank"
              rel="noopener noreferrer"
              className="block p-4 border rounded-lg hover:bg-gray-50 transition-colors"
            >
              <div className="font-medium">Laravel API</div>
              <div className="text-sm text-gray-600">Backend Services</div>
              <div className="text-xs text-blue-600">localhost:8000</div>
            </a>
            
            <a
              href="http://localhost:3000"
              target="_blank"
              rel="noopener noreferrer"
              className="block p-4 border rounded-lg hover:bg-gray-50 transition-colors"
            >
              <div className="font-medium">Customer Website</div>
              <div className="text-sm text-gray-600">Next.js Frontend</div>
              <div className="text-xs text-blue-600">localhost:3000</div>
            </a>
            
            <a
              href="http://localhost:3001"
              target="_blank"
              rel="noopener noreferrer"
              className="block p-4 border rounded-lg hover:bg-gray-50 transition-colors"
            >
              <div className="font-medium">POS System</div>
              <div className="text-sm text-gray-600">React Dashboard</div>
              <div className="text-xs text-blue-600">localhost:3001</div>
            </a>
          </div>
        </div>

        <div className="mt-8 text-center">
          <p className="text-sm text-gray-500">
            🔧 All accounts are fully functional and ready for testing
          </p>
        </div>
      </div>
    </div>
  );
}