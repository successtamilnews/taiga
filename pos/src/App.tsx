import React from 'react';
import { Routes, Route } from 'react-router-dom';
import Layout from './components/Layout.tsx';
import Dashboard from './pages/Dashboard.tsx';
import PointOfSale from './pages/PointOfSale.tsx';
import Products from './pages/Products.tsx';
import Inventory from './pages/Inventory.tsx';
import Reports from './pages/Reports.tsx';
import Settings from './pages/Settings.tsx';
import Login from './pages/Login.tsx';
import { AuthProvider, useAuth } from './contexts/AuthContext.tsx';

function AppRoutes() {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    return <Login />;
  }

  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/pos" element={<PointOfSale />} />
        <Route path="/products" element={<Products />} />
        <Route path="/inventory" element={<Inventory />} />
        <Route path="/reports" element={<Reports />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Layout>
  );
}

function App() {
  return (
    <AuthProvider>
      <div className="App">
        <AppRoutes />
      </div>
    </AuthProvider>
  );
}

export default App;