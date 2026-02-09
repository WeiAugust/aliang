import { Routes, Route, Navigate } from 'react-router-dom'
import type { ReactElement } from 'react'
import { ConfigProvider, App as AntdApp, theme } from 'antd'
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
  const { defaultAlgorithm } = theme

  return (
    <ConfigProvider
      theme={{
        algorithm: defaultAlgorithm,
        token: {
          colorPrimary: '#4f6ef7',
          colorInfo: '#4f6ef7',
          colorSuccess: '#12b886',
          colorWarning: '#f59f00',
          colorError: '#f03e3e',
          colorText: '#0f172a',
          colorTextSecondary: '#64748b',
          colorBgLayout: '#eef2f9',
          colorBgContainer: '#ffffff',
          colorBorderSecondary: '#e4e9f3',
          borderRadius: 12,
          borderRadiusLG: 16,
          boxShadowSecondary: '0 18px 42px rgba(15, 23, 42, 0.08)',
          fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', sans-serif",
        },
        components: {
          Layout: {
            bodyBg: 'transparent',
            headerBg: 'transparent',
            siderBg: 'transparent',
            triggerBg: 'transparent',
          },
          Card: {
            headerBg: 'transparent',
            bodyPadding: 20,
          },
          Table: {
            headerBg: '#f8faff',
            rowHoverBg: '#f4f7ff',
            borderColor: '#e5eaf5',
            headerColor: '#334155',
          },
          Menu: {
            darkItemBg: 'transparent',
            darkSubMenuItemBg: 'transparent',
            darkItemColor: 'rgba(229, 236, 255, 0.78)',
            darkItemHoverColor: '#ffffff',
            darkItemSelectedColor: '#ffffff',
            darkItemSelectedBg: 'rgba(79, 110, 247, 0.38)',
          },
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
