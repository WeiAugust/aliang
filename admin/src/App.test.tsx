import { screen } from '@testing-library/react'
import { describe, it, expect, beforeEach } from 'vitest'
import { MemoryRouter } from 'react-router-dom'
import { ConfigProvider, App as AntdApp } from 'antd'
import App from './App'
import { render } from '@testing-library/react'

describe('App routes', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('renders App component without crashing', () => {
    render(
      <ConfigProvider>
        <AntdApp>
          <MemoryRouter initialEntries={['/login']}>
            <App />
          </MemoryRouter>
        </AntdApp>
      </ConfigProvider>
    )

    // Verify the login page renders since we're starting from /login
    expect(screen.getByText('Aliang Admin')).toBeInTheDocument()
  })
})
