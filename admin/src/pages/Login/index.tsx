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
    } catch {
      message.error('Login failed - please check your connection')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-page">
      <Card
        title={<div className="login-title">Aliang Admin</div>}
        className="login-card"
        styles={{ header: { borderBottom: 'none', paddingBottom: 0, paddingTop: 26 } }}
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
              prefix={<UserOutlined className="field-prefix-icon" />}
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
              prefix={<LockOutlined className="field-prefix-icon" />}
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
              className="login-submit-btn"
            >
              Sign In
            </Button>
          </Form.Item>
        </Form>

        <div className="login-demo-card">
          <strong>Demo Credentials:</strong>
          <br />
          Username: admin
          <br />
          Password: admin123
        </div>
      </Card>
    </div>
  )
}
