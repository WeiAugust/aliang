import { Routes, Route, Navigate } from 'react-router-dom'
import type { ReactElement } from 'react'
import { ConfigProvider, App as AntdApp } from 'antd'
import LoginPage from './pages/Login'
import DashboardPage from './pages/Dashboard'
import PostsPage from './pages/Posts'
import PostDetailPage from './pages/PostDetail'
import UsersPage from './pages/Users'
import UserDetailPage from './pages/UserDetail'
import AdminLayout from './layouts/AdminLayout'
import { useAuthStore } from '@/stores/useAuthStore'

function RequireAuth({ children }: { children: ReactElement }) {
  const { isAuthenticated, isTokenExpired } = useAuthStore()

  if (!isAuthenticated || isTokenExpired()) {
    return <Navigate to="/login" replace />
  }

  return children
}

function RedirectIfAuthenticated({ children }: { children: ReactElement }) {
  const { isAuthenticated, isTokenExpired } = useAuthStore()

  if (isAuthenticated && !isTokenExpired()) {
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
            <Route path="posts/:id" element={<PostDetailPage />} />
            <Route path="users" element={<UsersPage />} />
            <Route path="users/:id" element={<UserDetailPage />} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AntdApp>
    </ConfigProvider>
  )
}

export default App
