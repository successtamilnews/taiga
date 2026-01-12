import { apiClient } from './api'
import { ApiResponse, PaymentMethod } from '@/types'

export interface PaymentRequest {
  amount: number
  currency: string
  order_id: string
  payment_method: string
  billing_address?: any
  metadata?: any
}

export interface PaymentResult {
  success: boolean
  payment_id?: string
  redirect_url?: string
  error?: string
}

export const paymentService = {
  // Get available payment methods
  async getPaymentMethods(): Promise<ApiResponse<PaymentMethod[]>> {
    return await apiClient.get('/api/payments/methods')
  },

  // Google Pay Integration
  async initiateGooglePay(request: PaymentRequest): Promise<ApiResponse<any>> {
    return await apiClient.post('/api/payments/google-pay/initiate', request)
  },

  async processGooglePay(paymentToken: string, orderId: string): Promise<ApiResponse<PaymentResult>> {
    return await apiClient.post('/api/payments/google-pay/process', {
      payment_token: paymentToken,
      order_id: orderId
    })
  },

  // Apple Pay Integration
  async initiateApplePay(request: PaymentRequest): Promise<ApiResponse<any>> {
    return await apiClient.post('/api/payments/apple-pay/initiate', request)
  },

  async processApplePay(paymentData: any, orderId: string): Promise<ApiResponse<PaymentResult>> {
    return await apiClient.post('/api/payments/apple-pay/process', {
      payment_data: paymentData,
      order_id: orderId
    })
  },

  // Sampath Bank IPG Integration
  async initiateSampathBank(request: PaymentRequest): Promise<ApiResponse<any>> {
    return await apiClient.post('/api/payments/sampath-bank/initiate', request)
  },

  async processSampathBank(paymentData: any): Promise<ApiResponse<PaymentResult>> {
    return await apiClient.post('/api/payments/sampath-bank/process', paymentData)
  },

  // Credit Card Processing
  async processCreditCard(cardData: any, orderId: string): Promise<ApiResponse<PaymentResult>> {
    return await apiClient.post('/api/payments/credit-card/process', {
      card_data: cardData,
      order_id: orderId
    })
  },

  // Bank Transfer
  async initiateBankTransfer(request: PaymentRequest): Promise<ApiResponse<any>> {
    return await apiClient.post('/api/payments/bank-transfer/initiate', request)
  },

  // Payment Status Check
  async getPaymentStatus(paymentId: string): Promise<ApiResponse<any>> {
    return await apiClient.get(`/api/payments/${paymentId}/status`)
  },

  // Payment Verification
  async verifyPayment(paymentId: string, verificationData?: any): Promise<ApiResponse<PaymentResult>> {
    return await apiClient.post(`/api/payments/${paymentId}/verify`, verificationData || {})
  },

  // Refund Processing
  async processRefund(paymentId: string, amount?: number, reason?: string): Promise<ApiResponse<any>> {
    return await apiClient.post(`/api/payments/${paymentId}/refund`, {
      amount,
      reason
    })
  }
}

// Google Pay Helper Functions
export class GooglePayService {
  private static isGooglePayReady = false
  private static googlePayClient: any = null

  static async initialize() {
    if (typeof window === 'undefined' || !window.google?.payments?.api) {
      throw new Error('Google Pay API is not available')
    }

    this.googlePayClient = new window.google.payments.api.PaymentsClient({
      environment: process.env.NODE_ENV === 'production' ? 'PRODUCTION' : 'TEST'
    })

    this.isGooglePayReady = await this.googlePayClient.isReadyToPay({
      apiVersion: 2,
      apiVersionMinor: 0,
      allowedPaymentMethods: [{
        type: 'CARD',
        parameters: {
          allowedAuthMethods: ['PAN_ONLY', 'CRYPTOGRAM_3DS'],
          allowedCardNetworks: ['MASTERCARD', 'VISA']
        }
      }]
    })

    return this.isGooglePayReady
  }

  static async requestPayment(amount: number, currency: string = 'LKR') {
    if (!this.isGooglePayReady) {
      throw new Error('Google Pay is not ready')
    }

    const paymentDataRequest = {
      apiVersion: 2,
      apiVersionMinor: 0,
      allowedPaymentMethods: [{
        type: 'CARD',
        parameters: {
          allowedAuthMethods: ['PAN_ONLY', 'CRYPTOGRAM_3DS'],
          allowedCardNetworks: ['MASTERCARD', 'VISA']
        },
        tokenizationSpecification: {
          type: 'PAYMENT_GATEWAY',
          parameters: {
            gateway: 'example',
            gatewayMerchantId: process.env.NEXT_PUBLIC_GOOGLE_PAY_MERCHANT_ID
          }
        }
      }],
      merchantInfo: {
        merchantId: process.env.NEXT_PUBLIC_GOOGLE_PAY_MERCHANT_ID,
        merchantName: 'Taiga Marketplace'
      },
      transactionInfo: {
        totalPriceStatus: 'FINAL',
        totalPrice: (amount / 100).toString(),
        currencyCode: currency
      }
    }

    return await this.googlePayClient.loadPaymentData(paymentDataRequest)
  }
}

// Apple Pay Helper Functions
export class ApplePayService {
  private static isApplePayReady = false

  static async initialize() {
    if (typeof window === 'undefined' || !window.ApplePaySession) {
      throw new Error('Apple Pay is not available')
    }

    this.isApplePayReady = ApplePaySession.canMakePayments() && 
                          ApplePaySession.canMakePaymentsWithActiveCard(
                            process.env.NEXT_PUBLIC_APPLE_PAY_MERCHANT_ID!
                          )

    return this.isApplePayReady
  }

  static async requestPayment(amount: number, currency: string = 'LKR') {
    if (!this.isApplePayReady) {
      throw new Error('Apple Pay is not ready')
    }

    const request = {
      countryCode: 'LK',
      currencyCode: currency,
      supportedNetworks: ['visa', 'masterCard'],
      merchantCapabilities: ['supports3DS'],
      total: {
        label: 'Taiga Marketplace',
        amount: (amount / 100).toString()
      }
    }

    const session = new ApplePaySession(3, request)
    
    return new Promise((resolve, reject) => {
      session.onvalidatemerchant = async (event: any) => {
        try {
          // Validate with your server
          const validation = await fetch('/api/apple-pay/validate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ validationURL: event.validationURL })
          })
          const merchantSession = await validation.json()
          session.completeMerchantValidation(merchantSession)
        } catch (error) {
          reject(error)
        }
      }

      session.onpaymentauthorized = (event: any) => {
        resolve(event.payment)
        session.completePayment(ApplePaySession.STATUS_SUCCESS)
      }

      session.oncancel = () => {
        reject(new Error('Payment cancelled'))
      }

      session.begin()
    })
  }
}

// Sampath Bank IPG Helper Functions
export class SampathBankService {
  static generatePaymentForm(paymentData: any) {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = process.env.NEXT_PUBLIC_SAMPATH_BANK_URL!

    Object.keys(paymentData).forEach(key => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = key
      input.value = paymentData[key]
      form.appendChild(input)
    })

    document.body.appendChild(form)
    form.submit()
    document.body.removeChild(form)
  }

  static async initiatePayment(orderData: any) {
    try {
      const response = await paymentService.initiateSampathBank(orderData)
      if (response.success && response.data) {
        this.generatePaymentForm(response.data.form_data)
      }
      return response
    } catch (error) {
      throw error
    }
  }
}