import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Form, Input, Button, Card, App as AntdApp } from 'antd'
import { UserOutlined, LockOutlined } from '@ant-design/icons'
import { authApi } from '@/services/api'
import { useAuthStore } from '@/stores/useAuthStore'

interface LoginForm {
  username: string
  password: string
}

export default function LoginPage() {
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const { message } = AntdApp.useApp()
  const setAuth = useAuthStore((state) => state.setAuth)

  const onFinish = async (values: LoginForm) => {
    setLoading(true)
    try {
      const response = await authApi.login(values)
      if (response.success && response.data) {
        setAuth(response.data.token, response.data.admin)
        message.success('Login successful')
        navigate('/dashboard')
      } else {
        message.error(response.error?.message || 'Invalid credentials')
      }
    } catch (error) {
      message.error('Login failed - please check your connection')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    }}>
      <Card
        title={
          <div style={{ textAlign: 'center', fontSize: 24, fontWeight: 600 }}>
            Aliang Admin
          </div>
        }
        style={{
          width: 400,
          borderRadius: 16,
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.15)',
        }}
        styles={{ header: { borderBottom: 'none', paddingBottom: 0 } }}
      >
        <Form
          name="login"
          onFinish={onFinish}
          autoComplete="off"
          size="large"
          layout="vertical"
        >
          <Form.Item
            name="username"
            rules={[
              { required: true, message: 'Please input your username!' },
              { min: 3, message: 'Username must be at least 3 characters' },
            ]}
          >
            <Input
              prefix={<UserOutlined style={{ color: '#999' }} />}
              placeholder="Username"
              autoComplete="username"
            />
          </Form.Item>

          <Form.Item
            name="password"
            rules={[
              { required: true, message: 'Please input your password!' },
              { min: 4, message: 'Password must be at least 4 characters' },
            ]}
          >
            <Input.Password
              prefix={<LockOutlined style={{ color: '#999' }} />}
              placeholder="Password"
              autoComplete="current-password"
            />
          </Form.Item>

          <Form.Item style={{ marginBottom: 0, marginTop: 24 }}>
            <Button
              type="primary"
              htmlType="submit"
              loading={loading}
              block
              style={{
                height: 48,
                fontSize: 16,
                fontWeight: 500,
                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                border: 'none',
              }}
            >
              Sign In
            </Button>
          </Form.Item>
        </Form>

        <div style={{
          marginTop: 24,
          padding: '16px',
          background: '#f5f5f5',
          borderRadius: 8,
          fontSize: 12,
          color: '#666',
        }}>
          <strong>Demo Credentials:</strong><br />
          Username: admin<br />
          Password: admin123
        </div>
      </Card>
    </div>
  )
}
