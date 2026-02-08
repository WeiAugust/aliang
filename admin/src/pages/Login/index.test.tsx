import { screen } from '@testing-library/react'
import { describe, it, expect, beforeEach } from 'vitest'
import LoginPage from './index'
import { renderWithProviders } from '@/test/utils'

describe('LoginPage', () => {
  beforeEach(() => {
    localStorage.clear()
    window.history.pushState({}, '', '/login')
  })

  it('renders login form', () => {
    renderWithProviders(<LoginPage />)

    expect(screen.getByText('Aliang Admin')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Username')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Password')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument()
  })

  it('shows demo credentials info', () => {
    renderWithProviders(<LoginPage />)

    expect(screen.getByText('Demo Credentials:')).toBeInTheDocument()
  })
})
