// ===========================================
// API Client - Axios HTTP Client with interceptors
// ===========================================

import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1'

// Create axios instance
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Get token from sessionStorage (more secure than localStorage)
// Falls back to localStorage for backward compatibility
function getToken(): string | null {
  return sessionStorage.getItem('admin_token') || localStorage.getItem('admin_token')
}

// Clear all stored tokens on auth error
function clearTokens(): void {
  sessionStorage.removeItem('admin_token')
  sessionStorage.removeItem('admin_token_expires')
  localStorage.removeItem('admin_token')
}

// Request interceptor - add auth token
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = getToken()
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error: AxiosError) => {
    return Promise.reject(error)
  }
)

// Response interceptor - handle errors
apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    // Handle 401 Unauthorized - redirect to login
    if (error.response?.status === 401) {
      clearTokens()
      if (window.location.pathname !== '/login') {
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  }
)

export default apiClient
