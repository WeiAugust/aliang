import { screen, waitFor } from '@testing-library/react'
import { describe, it, expect, beforeEach } from 'vitest'
import PostsPage from './index'
import { renderWithProviders } from '@/test/utils'

describe('PostsPage', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('renders page header', async () => {
    renderWithProviders(<PostsPage />)

    await waitFor(() => {
      expect(screen.getByRole('heading', { name: 'Content Management' })).toBeInTheDocument()
    })
  })
})
