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
      } catch {
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
        <div className="page-header">
          <div>
            <h1 className="page-title">Dashboard</h1>
            <p className="page-title-subtle">Platform overview and live metrics</p>
          </div>
        </div>
        <Row gutter={[16, 16]}>
          {[1, 2, 3, 4].map((item) => (
            <Col xs={24} sm={12} lg={6} key={item}>
              <Card className="page-card">
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
        <div className="page-header">
          <div>
            <h1 className="page-title">Dashboard</h1>
            <p className="page-title-subtle">Platform overview and live metrics</p>
          </div>
        </div>
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
      <div className="page-header">
        <div>
          <h1 className="page-title">Dashboard</h1>
          <p className="page-title-subtle">Platform overview and live metrics</p>
        </div>
      </div>

      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={6}>
          <Card
            hoverable
            styles={{ body: { padding: '20px 24px' } }}
            className="dashboard-card"
          >
            <Statistic
              title={<span className="dashboard-kpi-title">Total Users</span>}
              value={stats?.total_users || 0}
              prefix={<UserOutlined className="kpi-icon users" />}
              valueStyle={{ color: '#0f172a', fontSize: 30, fontWeight: 700 }}
              suffix={
                <span className="metric-positive">
                  <ArrowUpOutlined /> Active
                </span>
              }
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card
            hoverable
            styles={{ body: { padding: '20px 24px' } }}
            className="dashboard-card"
          >
            <Statistic
              title={<span className="dashboard-kpi-title">Total Posts</span>}
              value={stats?.total_posts || 0}
              prefix={<FileTextOutlined className="kpi-icon posts" />}
              valueStyle={{ color: '#0f172a', fontSize: 30, fontWeight: 700 }}
              suffix={
                <span className="metric-positive">
                  <ArrowUpOutlined /> New
                </span>
              }
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card
            hoverable
            styles={{ body: { padding: '20px 24px' } }}
            className="dashboard-card"
          >
            <Statistic
              title={<span className="dashboard-kpi-title">Total Likes</span>}
              value={stats?.total_likes || 0}
              prefix={<LikeOutlined className="kpi-icon likes" />}
              valueStyle={{ color: '#0f172a', fontSize: 30, fontWeight: 700 }}
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
            styles={{ body: { padding: '20px 24px' } }}
            className="dashboard-card"
          >
            <Statistic
              title={<span className="dashboard-kpi-title">Total Comments</span>}
              value={stats?.total_comments || 0}
              prefix={<CommentOutlined className="kpi-icon comments" />}
              valueStyle={{ color: '#0f172a', fontSize: 30, fontWeight: 700 }}
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

      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24} lg={12}>
          <Card
            title={<span className="stats-card-header">Daily Activity</span>}
            className="page-card"
            styles={{ header: { borderBottom: '1px solid #edf1f8' } }}
          >
            <Row gutter={16}>
              <Col span={12}>
                <Statistic
                  title="Active Users Today"
                  value={stats?.daily_active_users || 0}
                  valueStyle={{ color: '#3657ea', fontWeight: 600 }}
                />
              </Col>
              <Col span={12}>
                <Statistic
                  title="New Posts Today"
                  value={stats?.daily_new_posts || 0}
                  valueStyle={{ color: '#0ea5e9', fontWeight: 600 }}
                />
              </Col>
            </Row>
          </Card>
        </Col>

        <Col xs={24} lg={12}>
          <Card
            title={<span className="stats-card-header">Platform Health</span>}
            className="page-card"
            styles={{ header: { borderBottom: '1px solid #edf1f8' } }}
          >
            <Row gutter={16}>
              <Col span={8}>
                <Statistic
                  title="Engagement Rate"
                  value={stats?.total_likes ? ((stats.total_likes / (stats.total_posts || 1)) * 100).toFixed(1) : 0}
                  suffix="%"
                  valueStyle={{ color: '#10b981', fontWeight: 600 }}
                />
              </Col>
              <Col span={8}>
                <Statistic
                  title="Avg Comments/Post"
                  value={stats?.total_comments ? (stats.total_comments / (stats.total_posts || 1)).toFixed(1) : 0}
                  valueStyle={{ color: '#0ea5e9', fontWeight: 600 }}
                />
              </Col>
              <Col span={8}>
                <Statistic
                  title="User Activity"
                  value={stats?.total_users ? (stats.total_posts / stats.total_users).toFixed(1) : 0}
                  suffix="/user"
                  valueStyle={{ color: '#3657ea', fontWeight: 600 }}
                />
              </Col>
            </Row>
          </Card>
        </Col>
      </Row>
    </div>
  )
}
