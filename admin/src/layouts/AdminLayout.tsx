import { useMemo, useState } from 'react'
import { Outlet, useNavigate, useLocation } from 'react-router-dom'
import { Layout, Menu, Button, Avatar, Dropdown, Typography } from 'antd'
import {
  DashboardOutlined,
  FileTextOutlined,
  UserOutlined,
  LogoutOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
} from '@ant-design/icons'
import type { MenuProps } from 'antd'
import { useAuthStore } from '@/stores/useAuthStore'

const { Header, Sider, Content } = Layout
const { Text } = Typography

export default function AdminLayout() {
  const [collapsed, setCollapsed] = useState(false)
  const navigate = useNavigate()
  const location = useLocation()
  const { user, logout } = useAuthStore()

  const selectedMenuKey = useMemo(() => {
    if (location.pathname.startsWith('/posts')) {
      return '/posts'
    }

    if (location.pathname.startsWith('/users')) {
      return '/users'
    }

    return '/dashboard'
  }, [location.pathname])

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const menuItems: MenuProps['items'] = [
    {
      key: '/dashboard',
      icon: <DashboardOutlined />,
      label: 'Dashboard',
      onClick: () => navigate('/dashboard'),
      title: 'Dashboard',
    },
    {
      key: '/posts',
      icon: <FileTextOutlined />,
      label: 'Posts',
      onClick: () => navigate('/posts'),
      title: 'Posts',
    },
    {
      key: '/users',
      icon: <UserOutlined />,
      label: 'Users',
      onClick: () => navigate('/users'),
      title: 'Users',
    },
  ]

  const userMenuItems: MenuProps['items'] = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: 'Profile',
      disabled: true,
      title: 'Profile management coming soon',
    },
    {
      type: 'divider',
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: 'Logout',
      onClick: handleLogout,
      danger: true,
    },
  ]

  return (
    <Layout className="admin-shell">
      <Sider
        width={244}
        collapsedWidth={86}
        trigger={null}
        collapsible
        collapsed={collapsed}
        className="admin-sider"
      >
        <div className={`admin-brand ${collapsed ? 'collapsed' : ''}`}>
          <span className="admin-brand-mark">A</span>
          {!collapsed && <span className="admin-brand-text">ALIANG</span>}
        </div>
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[selectedMenuKey]}
          items={menuItems}
          className="admin-nav"
        />
      </Sider>

      <Layout className="admin-main">
        <Header className="admin-header">
          <Button
            type="text"
            icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={() => setCollapsed(!collapsed)}
            className="header-toggle"
          />

          <Dropdown menu={{ items: userMenuItems }} placement="bottomRight">
            <div className="admin-user-trigger">
              <Avatar icon={<UserOutlined />} className="admin-user-avatar" />
              <div className="admin-user-meta">
                <span className="admin-user-name">{user?.username || 'Admin'}</span>
                <Text type="secondary">Administrator</Text>
              </div>
            </div>
          </Dropdown>
        </Header>

        <Content className="admin-content">
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  )
}
