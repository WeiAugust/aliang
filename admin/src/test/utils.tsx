import type { ReactElement } from 'react'
import { BrowserRouter } from 'react-router-dom'
import { ConfigProvider, App as AntdApp } from 'antd'
import { render } from '@testing-library/react'

export function renderWithProviders(ui: ReactElement) {
  return render(
    <ConfigProvider
      theme={{
        token: {
          colorPrimary: '#1890ff',
        },
      }}
    >
      <AntdApp>
        <BrowserRouter
          future={{
            v7_startTransition: true,
            v7_relativeSplatPath: true,
          }}
        >
          {ui}
        </BrowserRouter>
      </AntdApp>
    </ConfigProvider>,
  )
}
