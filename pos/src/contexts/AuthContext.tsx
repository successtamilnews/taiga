import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { apiService } from '../services/apiService.ts';

interface User {
  id: number;
  name: string;
  email: string;
  role: string;
  vendor_id?: number;
}

interface AuthContextType {
  isAuthenticated: boolean;
  user: User | null;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => void;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkAuthStatus();
  }, []);

  const checkAuthStatus = async () => {
    try {
      const token = localStorage.getItem('pos_token');
      if (token) {
        apiService.setAuthToken(token);
        const response = await apiService.get('/user');
        setUser(response.data.user);
        setIsAuthenticated(true);
      }
    } catch (error) {
      localStorage.removeItem('pos_token');
      apiService.setAuthToken(null);
    } finally {
      setLoading(false);
    }
  };

  const login = async (email: string, password: string): Promise<boolean> => {
    try {
      const response = await apiService.post('/login', { email, password });
      const { token, user } = response.data;
      
      localStorage.setItem('pos_token', token);
      apiService.setAuthToken(token);
      setUser(user);
      setIsAuthenticated(true);
      return true;
    } catch (error) {
      console.error('Login failed:', error);
      return false;
    }
  };

  const logout = () => {
    localStorage.removeItem('pos_token');
    apiService.setAuthToken(null);
    setUser(null);
    setIsAuthenticated(false);
  };

  const value = {
    isAuthenticated,
    user,
    login,
    logout,
    loading
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}