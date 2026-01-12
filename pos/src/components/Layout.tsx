import React, { ReactNode } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext.tsx';
import {
  HomeIcon,
  CurrencyDollarIcon,
  CubeIcon,
  ArchiveBoxIcon,
  ChartBarIcon,
  CogIcon,
  ArrowRightOnRectangleIcon,
} from '@heroicons/react/24/outline';

interface LayoutProps {
  children: ReactNode;
}

const navigation = [
  { name: 'Dashboard', href: '/', icon: HomeIcon },
  { name: 'Point of Sale', href: '/pos', icon: CurrencyDollarIcon },
  { name: 'Products', href: '/products', icon: CubeIcon },
  { name: 'Inventory', href: '/inventory', icon: ArchiveBoxIcon },
  { name: 'Reports', href: '/reports', icon: ChartBarIcon },
  { name: 'Settings', href: '/settings', icon: CogIcon },
];

function classNames(...classes: string[]) {
  return classes.filter(Boolean).join(' ');
}

export default function Layout({ children }: LayoutProps) {
  const location = useLocation();
  const { user, logout } = useAuth();

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="flex">
        {/* Sidebar */}
        <div className="fixed inset-y-0 left-0 z-50 w-64 bg-gray-900 text-white">
          <div className="flex h-16 items-center justify-center border-b border-gray-700">
            <h1 className="text-xl font-bold">Taiga POS</h1>
          </div>
          
          <nav className="mt-5 px-2">
            <ul className="space-y-1">
              {navigation.map((item) => {
                const isActive = location.pathname === item.href;
                return (
                  <li key={item.name}>
                    <Link
                      to={item.href}
                      className={classNames(
                        isActive
                          ? 'bg-gray-800 text-white'
                          : 'text-gray-300 hover:bg-gray-700 hover:text-white',
                        'group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold'
                      )}
                    >
                      <item.icon className="h-6 w-6 shrink-0" aria-hidden="true" />
                      {item.name}
                    </Link>
                  </li>
                );
              })}
            </ul>
          </nav>

          {/* User info and logout */}
          <div className="absolute bottom-0 left-0 right-0 p-4 border-t border-gray-700">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="h-8 w-8 rounded-full bg-gray-600 flex items-center justify-center">
                  <span className="text-sm font-medium">
                    {user?.name.charAt(0).toUpperCase()}
                  </span>
                </div>
              </div>
              <div className="ml-3">
                <p className="text-sm font-medium">{user?.name}</p>
                <p className="text-xs text-gray-400">{user?.role}</p>
              </div>
              <button
                onClick={logout}
                className="ml-auto text-gray-400 hover:text-white"
                title="Logout"
              >
                <ArrowRightOnRectangleIcon className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>

        {/* Main content */}
        <div className="flex-1 ml-64">
          <header className="bg-white shadow">
            <div className="px-6 py-4">
              <h1 className="text-2xl font-bold text-gray-900">
                {navigation.find(item => item.href === location.pathname)?.name || 'Dashboard'}
              </h1>
            </div>
          </header>
          
          <main className="flex-1 p-6">
            {children}
          </main>
        </div>
      </div>
    </div>
  );
}