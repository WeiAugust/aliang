import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import {
  Card,
  Descriptions,
  Table,
  Tag,
  Button,
  Space,
  Skeleton,
  Alert,
  Avatar,
  Row,
  Col,
  Statistic,
} from 'antd'
import {
  ArrowLeftOutlined,
  UserOutlined,
  FileTextOutlined,
  LikeOutlined,
  CommentOutlined,
} from '@ant-design/icons'
import { usersApi } from '@/services/api'
import type { UserDetail as UserDetailType } from '@/types'
import { formatDate, getStatusConfig, getRoleColor } from '@/utils'

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [user, setUser] = useState<UserDetailType | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchUser = async () => {
      if (!id) return

      try {
        setLoading(true)
        setError(null)
        const response = await usersApi.getUserDetail(Number(id))
        if (response.success && response.data) {
          setUser(response.data)
        } else {
          setError(response.error?.message || 'Failed to load user')
        }
      } catch {
        setError('Network error - please check your connection')
      } finally {
        setLoading(false)
      }
    }

    fetchUser()
  }, [id])

  if (loading) {
    return (
      <div>
        <Skeleton active paragraph={{ rows: 10 }} />
      </div>
    )
  }

  if (error || !user) {
    return (
      <div>
        <Button
          type="link"
          icon={<ArrowLeftOutlined />}
          onClick={() => navigate('/users')}
          style={{ marginBottom: 16, paddingLeft: 0 }}
        >
          Back to Users
        </Button>
        <Alert type="error" message="Failed to load user" description={error} showIcon />
      </div>
    )
  }

  const statusConfig = getStatusConfig(user.status)

  return (
    <div>
      <Button
        type="link"
        icon={<ArrowLeftOutlined />}
        onClick={() => navigate('/users')}
        style={{ marginBottom: 16, paddingLeft: 0 }}
      >
        Back to Users
      </Button>

      <Row gutter={[16, 16]}>
        <Col xs={24} lg={8}>
          <Card style={{ borderRadius: 12 }}>
            <div style={{ textAlign: 'center', marginBottom: 24 }}>
              <Avatar
                size={100}
                src={user.avatar_url || undefined}
                icon={!user.avatar_url ? <UserOutlined /> : undefined}
                style={{ backgroundColor: '#667eea' }}
              />
              <h2 style={{ margin: '16px 0 8px' }}>{user.nickname || 'Unknown'}</h2>
              <Tag color={getRoleColor(user.role)}>{user.role}</Tag>
            </div>

            <Descriptions column={1} size="small">
              <Descriptions.Item label="ID">#{user.id}</Descriptions.Item>
              <Descriptions.Item label="Phone">{user.phone}</Descriptions.Item>
              <Descriptions.Item label="Status">
                <Tag color={statusConfig.color}>{statusConfig.text}</Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Joined">{formatDate(user.created_at)}</Descriptions.Item>
              <Descriptions.Item label="Bio">{user.bio || '-'}</Descriptions.Item>
            </Descriptions>
          </Card>

          <Card style={{ borderRadius: 12, marginTop: 16 }}>
            <Row gutter={16}>
              <Col span={8}>
                <Statistic
                  title="Posts"
                  value={user.post_count || 0}
                  prefix={<FileTextOutlined />}
                  valueStyle={{ fontSize: 20 }}
                />
              </Col>
              <Col span={8}>
                <Statistic
                  title="Likes"
                  value={user.like_count || 0}
                  prefix={<LikeOutlined />}
                  valueStyle={{ fontSize: 20 }}
                />
              </Col>
              <Col span={8}>
                <Statistic
                  title="Comments"
                  value={user.comment_count || 0}
                  prefix={<CommentOutlined />}
                  valueStyle={{ fontSize: 20 }}
                />
              </Col>
            </Row>
          </Card>
        </Col>

        <Col xs={24} lg={16}>
          <Card
            title="Recent Posts"
            style={{ borderRadius: 12 }}
            styles={{ header: { borderBottom: '1px solid #f0f0f0' } }}
          >
            <Table
              dataSource={user.recent_posts}
              rowKey="id"
              pagination={false}
              size="small"
              columns={[
                {
                  title: 'ID',
                  dataIndex: 'id',
                  key: 'id',
                  width: 80,
                  render: (id: number) => <span style={{ color: '#999' }}>#{id}</span>,
                },
                {
                  title: 'Title',
                  dataIndex: 'title',
                  key: 'title',
                  ellipsis: true,
                },
                {
                  title: 'Visibility',
                  dataIndex: 'visibility',
                  key: 'visibility',
                  width: 100,
                  render: (visibility: string) => {
                    const config = getStatusConfig(visibility)
                    return <Tag color={config.color}>{config.text}</Tag>
                  },
                },
                {
                  title: 'Stats',
                  key: 'stats',
                  width: 120,
                  render: (_, record) => (
                    <Space size="small" style={{ fontSize: 12 }}>
                      <span>{record.like_count || 0} likes</span>
                      <span>{record.comment_count || 0} comments</span>
                    </Space>
                  ),
                },
                {
                  title: 'Created',
                  dataIndex: 'created_at',
                  key: 'created_at',
                  width: 180,
                  render: (date: string) => formatDate(date),
                },
              ]}
              locale={{ emptyText: 'No posts yet' }}
            />
          </Card>
        </Col>
      </Row>
    </div>
  )
}
