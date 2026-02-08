import { Card, Row, Col, Statistic, Skeleton, Alert } from 'antd'
import {
  UserOutlined,
  FileTextOutlined,
  LikeOutlined,
  CommentOutlined,
  ArrowUpOutlined,
} from '@ant-design/icons'
import { useEffect, useState } from 'react'
import { statsApi } from '@/services/api'
import type { DashboardStats } from '@/types'

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchStats = async () => {
      try {
        setLoading(true)
        setError(null)
        const response = await statsApi.getStats()
        if (response.success && response.data) {
          setStats(response.data)
        } else {
          setError(response.error?.message || 'Failed to load statistics')
        }
      } catch (err) {
        setError('Network error - please check your connection')
      } finally {
        setLoading(false)
      }
    }

    fetchStats()
  }, [])

  if (loading) {
    return (
      <div>
        <h1 style={{ marginBottom: 24 }}>Dashboard</h1>
        <Row gutter={[16, 16]}>
          {[1, 2, 3, 4].map((i) => (
            <Col xs={24} sm={12} lg={6} key={i}>
              <Card>
                <Skeleton active paragraph={{ rows: 2 }} />
              </Card>
            </Col>
          ))}
        </Row>
      </div>
    )
  }

  if (error) {
    return (
      <div>
        <h1 style={{ marginBottom: 24 }}>Dashboard</h1>
        <Alert
          type="error"
          message="Failed to load dashboard data"
          description={error}
          showIcon
        />
      </div>
    )
  }

  return (
    <div>
      <h1 style={{ marginBottom: 24, fontSize: 24, fontWeight: 600 }}>Dashboard</h1>

      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={6}>
          <Card
            hoverable
            style={{
              borderRadius: 12,
              transition: 'all 0.3s ease',
            }}
            styles={{ body: { padding: '20px 24px' } }}
            className="dashboard-card"
          >
            <Statistic
              title={
                <span style={{ color: '#666', fontSize: 14 }}>
                  Total Users
                </span>
              }
              value={stats?.total_users || 0}
              prefix={<UserOutlined style={{ color: '#667eea' }} />}
              valueStyle={{
                color: '#333',
                fontSize: 32,
                fontWeight: 600,
              }}
              suffix={
                <span style={{ fontSize: 14, color: '#52c41a', marginLeft: 8 }}>
                  <ArrowUpOutlined /> Active
                </span>
              }
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card
            hoverable
            style={{
              borderRadius: 12,
              transition: 'all 0.3s ease',
            }}
            styles={{ body: { padding: '20px 24px' } }}
            className="dashboard-card"
          >
            <Statistic
              title={
                <span style={{ color: '#666', fontSize: 14 }}>
                  Total Posts
                </span>
              }
              value={stats?.total_posts || 0}
              prefix={<FileTextOutlined style={{ color: '#1890ff' }} />}
              valueStyle={{
                color: '#333',
                fontSize: 32,
                fontWeight: 600,
              }}
              suffix={
                <span style={{ fontSize: 14, color: '#52c41a', marginLeft: 8 }}>
                  <ArrowUpOutlined /> New
                </span>
              }
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card
            hoverable
            style={{
              borderRadius: 12,
              transition: 'all 0.3s ease',
            }}
            styles={{ body: { padding: '20px 24px' } }}
            className="dashboard-card"
          >
            <Statistic
              title={
                <span style={{ color: '#666', fontSize: 14 }}>
                  Total Likes
                </span>
              }
              value={stats?.total_likes || 0}
              prefix={<LikeOutlined style={{ color: '#eb2f96' }} />}
              valueStyle={{
                color: '#333',
                fontSize: 32,
                fontWeight: 600,
              }}
              formatter={(value) => {
                const num = Number(value)
                if (num >= 1000000) {
                  return `${(num / 1000000).toFixed(1)}M`
                }
                if (num >= 1000) {
                  return `${(num / 1000).toFixed(1)}K`
                }
                return value
              }}
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card
            hoverable
            style={{
              borderRadius: 12,
              transition: 'all 0.3s ease',
            }}
            styles={{ body: { padding: '20px 24px' } }}
            className="dashboard-card"
          >
            <Statistic
              title={
                <span style={{ color: '#666', fontSize: 14 }}>
                  Total Comments
                </span>
              }
              value={stats?.total_comments || 0}
              prefix={<CommentOutlined style={{ color: '#52c41a' }} />}
              valueStyle={{
                color: '#333',
                fontSize: 32,
                fontWeight: 600,
              }}
              formatter={(value) => {
                const num = Number(value)
                if (num >= 1000000) {
                  return `${(num / 1000000).toFixed(1)}M`
                }
                if (num >= 1000) {
                  return `${(num / 1000).toFixed(1)}K`
                }
                return value
              }}
            />
          </Card>
        </Col>
      </Row>

      {/* Quick Stats Row */}
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24} lg={12}>
          <Card
            title="Daily Activity"
            style={{ borderRadius: 12 }}
            styles={{ header: { borderBottom: '1px solid #f0f0f0' } }}
          >
            <Row gutter={16}>
              <Col span={12}>
                <Statistic
                  title="Active Users Today"
                  value={stats?.daily_active_users || 0}
                  valueStyle={{ color: '#667eea', fontWeight: 600 }}
                />
              </Col>
              <Col span={12}>
                <Statistic
                  title="New Posts Today"
                  value={stats?.daily_new_posts || 0}
                  valueStyle={{ color: '#1890ff', fontWeight: 600 }}
                />
              </Col>
            </Row>
          </Card>
        </Col>

        <Col xs={24} lg={12}>
          <Card
            title="Platform Health"
            style={{ borderRadius: 12 }}
            styles={{ header: { borderBottom: '1px solid #f0f0f0' } }}
          >
            <Row gutter={16}>
              <Col span={8}>
                <Statistic
                  title="Engagement Rate"
                  value={stats?.total_likes ? ((stats.total_likes / (stats.total_posts || 1)) * 100).toFixed(1) : 0}
                  suffix="%"
                  valueStyle={{ color: '#52c41a', fontWeight: 600 }}
                />
              </Col>
              <Col span={8}>
                <Statistic
                  title="Avg Comments/Post"
                  value={stats?.total_comments ? (stats.total_comments / (stats.total_posts || 1)).toFixed(1) : 0}
                  valueStyle={{ color: '#1890ff', fontWeight: 600 }}
                />
              </Col>
              <Col span={8}>
                <Statistic
                  title="User Activity"
                  value={stats?.total_users ? ((stats.total_posts / stats.total_users)).toFixed(1) : 0}
                  suffix="/user"
                  valueStyle={{ color: '#667eea', fontWeight: 600 }}
                />
              </Col>
            </Row>
          </Card>
        </Col>
      </Row>
    </div>
  )
}
