// ===========================================
// Auth Store - Zustand state management for authentication
// ===========================================

import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { AdminUser } from '@/types'

interface AuthState {
  // State
  token: string | null
  user: AdminUser | null
  isAuthenticated: boolean
  isLoading: boolean

  // Actions
  setAuth: (token: string, user: AdminUser) => void
  logout: () => void
  clearAuth: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      isAuthenticated: false,
      isLoading: false,

      setAuth: (token, user) => {
        localStorage.setItem('admin_token', token)
        set({
          token,
          user,
          isAuthenticated: true,
        })
      },

      logout: () => {
        localStorage.removeItem('admin_token')
        set({
          token: null,
          user: null,
          isAuthenticated: false,
        })
      },

      clearAuth: () => {
        localStorage.removeItem('admin_token')
        set({
          token: null,
          user: null,
          isAuthenticated: false,
        })
      },
    }),
    {
      name: 'admin-auth-storage',
      partialize: (state) => ({
        token: state.token,
        user: state.user,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
)

// Selectors for common use cases
export const selectToken = (state: AuthState) => state.token
export const selectUser = (state: AuthState) => state.user
export const selectIsAuthenticated = (state: AuthState) => state.isAuthenticated
