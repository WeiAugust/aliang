import { Card, Row, Col, Statistic } from 'antd'
import { UserOutlined, FileTextOutlined, LikeOutlined, CommentOutlined } from '@ant-design/icons'

export default function DashboardPage() {
  // TODO: Fetch real data from API
  const stats = {
    totalUsers: 1234,
    totalPosts: 5678,
    totalLikes: 12345,
    totalComments: 6789,
  }

  return (
    <div>
      <h1 style={{ marginBottom: 24 }}>Dashboard</h1>

      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Total Users"
              value={stats.totalUsers}
              prefix={<UserOutlined />}
              valueStyle={{ color: '#3f8600' }}
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Total Posts"
              value={stats.totalPosts}
              prefix={<FileTextOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Total Likes"
              value={stats.totalLikes}
              prefix={<LikeOutlined />}
              valueStyle={{ color: '#cf1322' }}
            />
          </Card>
        </Col>

        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Total Comments"
              value={stats.totalComments}
              prefix={<CommentOutlined />}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
      </Row>
    </div>
  )
}
