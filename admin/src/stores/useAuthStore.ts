// ===========================================
// Auth Store - Zustand state management for authentication
// ===========================================

import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import type { AdminUser } from '@/types'

interface AuthState {
  // State
  token: string | null
  user: AdminUser | null
  isAuthenticated: boolean
  isLoading: boolean
  tokenExpiresAt: number | null

  // Actions
  setAuth: (token: string, user: AdminUser, expiresIn?: number) => void
  logout: () => void
  clearAuth: () => void
  isTokenExpired: () => boolean
}

// Token expiration buffer (5 minutes before actual expiry)
const EXPIRATION_BUFFER_MS = 5 * 60 * 1000

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      token: null,
      user: null,
      isAuthenticated: false,
      isLoading: false,
      tokenExpiresAt: null,

      setAuth: (token, user, expiresIn = 3600) => {
        // Calculate expiration time (default 1 hour)
        const expiresAt = Date.now() + expiresIn * 1000 - EXPIRATION_BUFFER_MS

        // Store token in localStorage via zustand persist
        // Also set sessionStorage for easier access during session
        sessionStorage.setItem('admin_token', token)
        sessionStorage.setItem('admin_token_expires', String(expiresAt))

        set({
          token,
          user,
          isAuthenticated: true,
          tokenExpiresAt: expiresAt,
        })
      },

      logout: () => {
        sessionStorage.removeItem('admin_token')
        sessionStorage.removeItem('admin_token_expires')
        set({
          token: null,
          user: null,
          isAuthenticated: false,
          tokenExpiresAt: null,
        })
      },

      clearAuth: () => {
        sessionStorage.removeItem('admin_token')
        sessionStorage.removeItem('admin_token_expires')
        set({
          token: null,
          user: null,
          isAuthenticated: false,
          tokenExpiresAt: null,
        })
      },

      isTokenExpired: () => {
        const { tokenExpiresAt } = get()
        if (!tokenExpiresAt) return true
        return Date.now() > tokenExpiresAt
      },
    }),
    {
      name: 'admin-auth-storage',
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({
        token: state.token,
        user: state.user,
        isAuthenticated: state.isAuthenticated,
        tokenExpiresAt: state.tokenExpiresAt,
      }),
    }
  )
)

// Selectors for common use cases
export const selectToken = (state: AuthState) => state.token
export const selectUser = (state: AuthState) => state.user
export const selectIsAuthenticated = (state: AuthState) => state.isAuthenticated
export const selectIsTokenExpired = (state: AuthState) => state.isTokenExpired()
