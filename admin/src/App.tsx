import { Routes, Route, Navigate } from 'react-router-dom'
import type { ReactElement } from 'react'
import { ConfigProvider, App as AntdApp } from 'antd'
import LoginPage from './pages/Login'
import DashboardPage from './pages/Dashboard'
import PostsPage from './pages/Posts'
import UsersPage from './pages/Users'
import AdminLayout from './layouts/AdminLayout'

function RequireAuth({ children }: { children: ReactElement }) {
  const token = localStorage.getItem('admin_token')

  if (!token) {
    return <Navigate to="/login" replace />
  }

  return children
}

function RedirectIfAuthenticated({ children }: { children: ReactElement }) {
  const token = localStorage.getItem('admin_token')

  if (token) {
    return <Navigate to="/dashboard" replace />
  }

  return children
}

function App() {
  return (
    <ConfigProvider
      theme={{
        token: {
          colorPrimary: '#1890ff',
        },
      }}
    >
      <AntdApp>
        <Routes>
          <Route
            path="/login"
            element={
              <RedirectIfAuthenticated>
                <LoginPage />
              </RedirectIfAuthenticated>
            }
          />
          <Route
            path="/"
            element={
              <RequireAuth>
                <AdminLayout />
              </RequireAuth>
            }
          >
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="dashboard" element={<DashboardPage />} />
            <Route path="posts" element={<PostsPage />} />
            <Route path="users" element={<UsersPage />} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AntdApp>
    </ConfigProvider>
  )
}

export default App
