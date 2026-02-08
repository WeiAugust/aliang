import { screen, waitFor } from '@testing-library/react'
import { describe, it, expect, beforeEach } from 'vitest'
import UsersPage from './index'
import { renderWithProviders } from '@/test/utils'

describe('UsersPage', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('renders page header', async () => {
    renderWithProviders(<UsersPage />)

    await waitFor(() => {
      expect(screen.getByRole('heading', { name: 'User Management' })).toBeInTheDocument()
    })
  })
})
