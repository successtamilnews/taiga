import React, { useState, useEffect } from 'react';
import { apiService } from '../services/apiService.ts';
import { 
  ShoppingCartIcon, 
  CurrencyDollarIcon, 
  UserGroupIcon, 
  CubeIcon,
  ArrowTrendingUpIcon,
  ArrowTrendingDownIcon
} from '@heroicons/react/24/outline';

interface DashboardStats {
  totalSales: number;
  totalOrders: number;
  totalCustomers: number;
  totalProducts: number;
  todaySales: number;
  todayOrders: number;
  salesGrowth: number;
  orderGrowth: number;
}

const StatCard = ({ 
  title, 
  value, 
  icon: Icon, 
  change, 
  changeType 
}: {
  title: string;
  value: string;
  icon: React.ComponentType<any>;
  change?: string;
  changeType?: 'increase' | 'decrease';
}) => (
  <div className="bg-white overflow-hidden shadow rounded-lg">
    <div className="p-5">
      <div className="flex items-center">
        <div className="flex-shrink-0">
          <Icon className="h-6 w-6 text-gray-400" aria-hidden="true" />
        </div>
        <div className="ml-5 w-0 flex-1">
          <dl>
            <dt className="text-sm font-medium text-gray-500 truncate">{title}</dt>
            <dd className="text-lg font-medium text-gray-900">{value}</dd>
          </dl>
        </div>
      </div>
      {change && (
        <div className="mt-2 flex items-center text-sm">
          {changeType === 'increase' ? (
            <ArrowTrendingUpIcon className="h-4 w-4 text-green-500 mr-1" />
          ) : (
            <ArrowTrendingDownIcon className="h-4 w-4 text-red-500 mr-1" />
          )}
          <span className={changeType === 'increase' ? 'text-green-600' : 'text-red-600'}>
            {change}
          </span>
          <span className="text-gray-500 ml-1">from last month</span>
        </div>
      )}
    </div>
  </div>
);

export default function Dashboard() {
  const [stats, setStats] = useState<DashboardStats>({
    totalSales: 0,
    totalOrders: 0,
    totalCustomers: 0,
    totalProducts: 0,
    todaySales: 0,
    todayOrders: 0,
    salesGrowth: 0,
    orderGrowth: 0
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardStats();
  }, []);

  const fetchDashboardStats = async () => {
    try {
      const response = await apiService.getDashboardStats();
      setStats(response.data);
    } catch (error) {
      console.error('Failed to fetch dashboard stats:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-6">
        <h2 className="text-lg font-medium text-gray-900">Overview</h2>
        <p className="text-sm text-gray-500">
          Your business performance at a glance
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4 mb-8">
        <StatCard
          title="Total Sales"
          value={`$${stats.totalSales.toLocaleString()}`}
          icon={CurrencyDollarIcon}
          change={`${stats.salesGrowth > 0 ? '+' : ''}${stats.salesGrowth}%`}
          changeType={stats.salesGrowth >= 0 ? 'increase' : 'decrease'}
        />
        <StatCard
          title="Total Orders"
          value={stats.totalOrders.toLocaleString()}
          icon={ShoppingCartIcon}
          change={`${stats.orderGrowth > 0 ? '+' : ''}${stats.orderGrowth}%`}
          changeType={stats.orderGrowth >= 0 ? 'increase' : 'decrease'}
        />
        <StatCard
          title="Total Customers"
          value={stats.totalCustomers.toLocaleString()}
          icon={UserGroupIcon}
        />
        <StatCard
          title="Total Products"
          value={stats.totalProducts.toLocaleString()}
          icon={CubeIcon}
        />
      </div>

      {/* Today's Performance */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 mb-8">
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Today's Performance</h3>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-sm text-gray-500">Sales</span>
                <span className="text-sm font-medium">${stats.todaySales.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-500">Orders</span>
                <span className="text-sm font-medium">{stats.todayOrders}</span>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Quick Actions</h3>
            <div className="space-y-3">
              <button className="w-full text-left px-3 py-2 text-sm font-medium text-indigo-600 bg-indigo-50 rounded-md hover:bg-indigo-100">
                Start New Sale
              </button>
              <button className="w-full text-left px-3 py-2 text-sm font-medium text-gray-700 bg-gray-50 rounded-md hover:bg-gray-100">
                View Today's Sales
              </button>
              <button className="w-full text-left px-3 py-2 text-sm font-medium text-gray-700 bg-gray-50 rounded-md hover:bg-gray-100">
                Manage Inventory
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white shadow rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Recent Activity</h3>
          <div className="text-sm text-gray-500">
            Recent sales and orders will appear here...
          </div>
        </div>
      </div>
    </div>
  );
}