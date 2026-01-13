export {}

declare global {
  interface Window {
    google?: {
      payments?: {
        api?: any
      }
    }
    ApplePaySession?: any
  }

  var ApplePaySession: any
}

