import React, { useState, useEffect } from 'react';
import { apiService } from '../services/apiService.ts';
import { 
  MagnifyingGlassIcon, 
  MinusIcon, 
  PlusIcon, 
  TrashIcon,
  PrinterIcon,
  CreditCardIcon,
  BanknotesIcon
} from '@heroicons/react/24/outline';

interface Product {
  id: number;
  name: string;
  price: number;
  stock: number;
  sku: string;
  category?: string;
}

interface CartItem extends Product {
  quantity: number;
  subtotal: number;
}

interface Customer {
  id: number;
  name: string;
  email: string;
  phone: string;
}

export default function PointOfSale() {
  const [products, setProducts] = useState<Product[]>([]);
  const [cart, setCart] = useState<CartItem[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [showCustomerSearch, setShowCustomerSearch] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState('cash');
  const [discount, setDiscount] = useState(0);
  const [tax, setTax] = useState(0.1); // 10% tax
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      const response = await apiService.getProducts({ 
        search: searchTerm,
        status: 'approved',
        limit: 50 
      });
      setProducts(response.data.data || []);
    } catch (error) {
      console.error('Failed to fetch products:', error);
    }
  };

  useEffect(() => {
    const debounce = setTimeout(() => {
      fetchProducts();
    }, 300);

    return () => clearTimeout(debounce);
  }, [searchTerm]);

  const addToCart = (product: Product) => {
    const existingItem = cart.find(item => item.id === product.id);
    
    if (existingItem) {
      if (existingItem.quantity < product.stock) {
        updateCartQuantity(product.id, existingItem.quantity + 1);
      }
    } else {
      const newItem: CartItem = {
        ...product,
        quantity: 1,
        subtotal: product.price
      };
      setCart([...cart, newItem]);
    }
  };

  const updateCartQuantity = (productId: number, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    setCart(cart.map(item => {
      if (item.id === productId) {
        return {
          ...item,
          quantity,
          subtotal: item.price * quantity
        };
      }
      return item;
    }));
  };

  const removeFromCart = (productId: number) => {
    setCart(cart.filter(item => item.id !== productId));
  };

  const clearCart = () => {
    setCart([]);
    setSelectedCustomer(null);
    setDiscount(0);
  };

  const subtotal = cart.reduce((sum, item) => sum + item.subtotal, 0);
  const discountAmount = subtotal * (discount / 100);
  const taxAmount = (subtotal - discountAmount) * tax;
  const total = subtotal - discountAmount + taxAmount;

  const searchCustomers = async (query: string) => {
    if (query.length < 2) return;
    
    try {
      const response = await apiService.searchCustomers(query);
      setCustomers(response.data || []);
    } catch (error) {
      console.error('Failed to search customers:', error);
    }
  };

  const processOrder = async () => {
    if (cart.length === 0) return;

    setLoading(true);
    try {
      const orderData = {
        customer_id: selectedCustomer?.id,
        items: cart.map(item => ({
          product_id: item.id,
          quantity: item.quantity,
          price: item.price
        })),
        subtotal,
        discount: discountAmount,
        tax: taxAmount,
        total,
        payment_method: paymentMethod,
        status: 'completed'
      };

      const response = await apiService.createOrder(orderData);
      
      if (response.data.success) {
        // Print receipt
        printReceipt(response.data.order);
        clearCart();
        alert('Order completed successfully!');
      }
    } catch (error) {
      console.error('Failed to process order:', error);
      alert('Failed to process order. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const printReceipt = (order: any) => {
    const receiptWindow = window.open('', '_blank');
    if (!receiptWindow) return;

    const receiptHTML = `
      <html>
        <head>
          <title>Receipt - ${order.id}</title>
          <style>
            body { font-family: monospace; width: 300px; margin: 0; padding: 10px; }
            .center { text-align: center; }
            .right { text-align: right; }
            .line { border-bottom: 1px dashed #000; margin: 5px 0; }
            table { width: 100%; }
            .total { font-weight: bold; font-size: 16px; }
          </style>
        </head>
        <body>
          <div class="center">
            <h2>Taiga Store</h2>
            <p>Receipt #${order.id}</p>
            <p>${new Date().toLocaleString()}</p>
          </div>
          <div class="line"></div>
          <table>
            ${cart.map(item => `
              <tr>
                <td>${item.name}</td>
                <td class="right">${item.quantity} x $${item.price.toFixed(2)}</td>
              </tr>
              <tr>
                <td></td>
                <td class="right">$${item.subtotal.toFixed(2)}</td>
              </tr>
            `).join('')}
          </table>
          <div class="line"></div>
          <table>
            <tr><td>Subtotal:</td><td class="right">$${subtotal.toFixed(2)}</td></tr>
            ${discount > 0 ? `<tr><td>Discount (${discount}%):</td><td class="right">-$${discountAmount.toFixed(2)}</td></tr>` : ''}
            <tr><td>Tax:</td><td class="right">$${taxAmount.toFixed(2)}</td></tr>
            <tr class="total"><td>Total:</td><td class="right">$${total.toFixed(2)}</td></tr>
          </table>
          <div class="line"></div>
          <div class="center">
            <p>Payment Method: ${paymentMethod.toUpperCase()}</p>
            ${selectedCustomer ? `<p>Customer: ${selectedCustomer.name}</p>` : ''}
            <p>Thank you for your business!</p>
          </div>
        </body>
      </html>
    `;

    receiptWindow.document.write(receiptHTML);
    receiptWindow.document.close();
    receiptWindow.print();
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-full">
      {/* Product Search & Grid */}
      <div className="lg:col-span-2">
        <div className="bg-white rounded-lg shadow">
          <div className="p-4 border-b">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search products..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
          
          <div className="p-4 max-h-96 overflow-y-auto">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {products.map((product) => (
                <div
                  key={product.id}
                  className="border border-gray-200 rounded-lg p-4 hover:shadow-md cursor-pointer"
                  onClick={() => addToCart(product)}
                >
                  <h3 className="font-medium text-sm">{product.name}</h3>
                  <p className="text-xs text-gray-500 mb-2">SKU: {product.sku}</p>
                  <div className="flex justify-between items-center">
                    <span className="font-bold text-indigo-600">${product.price.toFixed(2)}</span>
                    <span className="text-xs text-gray-500">Stock: {product.stock}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Cart & Checkout */}
      <div className="bg-white rounded-lg shadow flex flex-col">
        {/* Customer Selection */}
        <div className="p-4 border-b">
          <div className="relative">
            <button
              onClick={() => setShowCustomerSearch(!showCustomerSearch)}
              className="w-full text-left px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              {selectedCustomer ? selectedCustomer.name : 'Select Customer (Optional)'}
            </button>
            
            {showCustomerSearch && (
              <div className="absolute top-full left-0 right-0 bg-white border border-gray-300 rounded-md mt-1 z-10">
                <input
                  type="text"
                  placeholder="Search customers..."
                  className="w-full px-3 py-2 border-b focus:outline-none"
                  onChange={(e) => searchCustomers(e.target.value)}
                />
                <div className="max-h-40 overflow-y-auto">
                  {customers.map((customer) => (
                    <button
                      key={customer.id}
                      className="w-full text-left px-3 py-2 hover:bg-gray-100"
                      onClick={() => {
                        setSelectedCustomer(customer);
                        setShowCustomerSearch(false);
                      }}
                    >
                      {customer.name} - {customer.phone}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Cart Items */}
        <div className="flex-1 p-4 overflow-y-auto">
          {cart.length === 0 ? (
            <p className="text-gray-500 text-center">No items in cart</p>
          ) : (
            <div className="space-y-3">
              {cart.map((item) => (
                <div key={item.id} className="flex items-center justify-between">
                  <div className="flex-1">
                    <h4 className="text-sm font-medium">{item.name}</h4>
                    <p className="text-xs text-gray-500">${item.price.toFixed(2)} each</p>
                  </div>
                  
                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => updateCartQuantity(item.id, item.quantity - 1)}
                      className="p-1 text-gray-500 hover:text-gray-700"
                    >
                      <MinusIcon className="h-4 w-4" />
                    </button>
                    <span className="text-sm font-medium w-8 text-center">{item.quantity}</span>
                    <button
                      onClick={() => updateCartQuantity(item.id, item.quantity + 1)}
                      className="p-1 text-gray-500 hover:text-gray-700"
                      disabled={item.quantity >= item.stock}
                    >
                      <PlusIcon className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => removeFromCart(item.id)}
                      className="p-1 text-red-500 hover:text-red-700 ml-2"
                    >
                      <TrashIcon className="h-4 w-4" />
                    </button>
                  </div>
                  
                  <div className="text-sm font-medium ml-2 w-16 text-right">
                    ${item.subtotal.toFixed(2)}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Discount & Tax */}
        {cart.length > 0 && (
          <div className="p-4 border-t space-y-3">
            <div className="flex items-center justify-between">
              <label className="text-sm">Discount %:</label>
              <input
                type="number"
                min="0"
                max="100"
                value={discount}
                onChange={(e) => setDiscount(Number(e.target.value))}
                className="w-20 px-2 py-1 border border-gray-300 rounded text-sm"
              />
            </div>
            
            <div className="space-y-1 text-sm">
              <div className="flex justify-between">
                <span>Subtotal:</span>
                <span>${subtotal.toFixed(2)}</span>
              </div>
              {discount > 0 && (
                <div className="flex justify-between text-red-600">
                  <span>Discount ({discount}%):</span>
                  <span>-${discountAmount.toFixed(2)}</span>
                </div>
              )}
              <div className="flex justify-between">
                <span>Tax:</span>
                <span>${taxAmount.toFixed(2)}</span>
              </div>
              <div className="flex justify-between font-bold text-lg border-t pt-1">
                <span>Total:</span>
                <span>${total.toFixed(2)}</span>
              </div>
            </div>
          </div>
        )}

        {/* Payment & Checkout */}
        {cart.length > 0 && (
          <div className="p-4 border-t">
            <div className="mb-4">
              <label className="block text-sm font-medium mb-2">Payment Method:</label>
              <div className="flex space-x-2">
                <button
                  onClick={() => setPaymentMethod('cash')}
                  className={`flex-1 py-2 px-3 text-sm rounded ${
                    paymentMethod === 'cash'
                      ? 'bg-indigo-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  <BanknotesIcon className="h-4 w-4 inline mr-1" />
                  Cash
                </button>
                <button
                  onClick={() => setPaymentMethod('card')}
                  className={`flex-1 py-2 px-3 text-sm rounded ${
                    paymentMethod === 'card'
                      ? 'bg-indigo-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  <CreditCardIcon className="h-4 w-4 inline mr-1" />
                  Card
                </button>
              </div>
            </div>

            <div className="space-y-2">
              <button
                onClick={processOrder}
                disabled={loading}
                className="w-full bg-green-600 text-white py-3 px-4 rounded-lg hover:bg-green-700 disabled:opacity-50 font-medium"
              >
                {loading ? 'Processing...' : `Complete Sale - $${total.toFixed(2)}`}
              </button>
              
              <button
                onClick={clearCart}
                className="w-full bg-gray-300 text-gray-700 py-2 px-4 rounded-lg hover:bg-gray-400"
              >
                Clear Cart
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}