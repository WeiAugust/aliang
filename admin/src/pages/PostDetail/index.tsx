import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import {
  Card,
  Descriptions,
  Tag,
  Button,
  Space,
  Skeleton,
  Alert,
  Row,
  Col,
  Image,
} from 'antd'
import {
  ArrowLeftOutlined,
  LikeOutlined,
  CommentOutlined,
  LockOutlined,
  UnlockOutlined,
  StarOutlined,
  StarFilled,
} from '@ant-design/icons'
import { postsApi } from '@/services/api'
import type { Post } from '@/types'
import { formatDate, getStatusConfig } from '@/utils'

export default function PostDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [post, setPost] = useState<Post | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchPost = async () => {
      if (!id) return

      try {
        setLoading(true)
        setError(null)
        const response = await postsApi.getPostById(Number(id))
        if (response.success && response.data) {
          setPost(response.data)
        } else {
          setError(response.error?.message || 'Post not found')
        }
      } catch {
        setError('Network error - please check your connection')
      } finally {
        setLoading(false)
      }
    }

    fetchPost()
  }, [id])

  if (loading) {
    return (
      <div>
        <Skeleton active paragraph={{ rows: 15 }} />
      </div>
    )
  }

  if (error || !post) {
    return (
      <div>
        <Button
          type="link"
          icon={<ArrowLeftOutlined />}
          onClick={() => navigate('/posts')}
          style={{ marginBottom: 16, paddingLeft: 0 }}
        >
          Back to Posts
        </Button>
        <Alert type="error" message="Failed to load post" description={error} showIcon />
      </div>
    )
  }

  const visibilityConfig = getStatusConfig(post.visibility)
  const labelConfig = getStatusConfig(post.label)

  return (
    <div>
      <Button
        type="link"
        icon={<ArrowLeftOutlined />}
        onClick={() => navigate('/posts')}
        style={{ marginBottom: 16, paddingLeft: 0 }}
      >
        Back to Posts
      </Button>

      <Row gutter={[16, 16]}>
        <Col xs={24} lg={16}>
          <Card style={{ borderRadius: 12 }}>
            <Descriptions column={1} size="small">
              <Descriptions.Item label="ID">#{post.id}</Descriptions.Item>
              <Descriptions.Item label="Title">{post.title}</Descriptions.Item>
              <Descriptions.Item label="Author ID">#{post.user_id}</Descriptions.Item>
              <Descriptions.Item label="Visibility">
                <Tag color={visibilityConfig.color} icon={post.visibility === 'public' ? <UnlockOutlined /> : <LockOutlined />}>
                  {visibilityConfig.text}
                </Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Label">
                <Tag
                  color={labelConfig.color}
                  icon={post.label === 'recommended' ? <StarFilled /> : post.label === 'not_recommended' ? <StarOutlined /> : undefined}
                >
                  {labelConfig.text}
                </Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Created">{formatDate(post.created_at)}</Descriptions.Item>
              <Descriptions.Item label="Updated">{post.updated_at ? formatDate(post.updated_at) : '-'}</Descriptions.Item>
            </Descriptions>

            <div style={{ marginTop: 24 }}>
              <h4>Content</h4>
              <div style={{ whiteSpace: 'pre-wrap', lineHeight: 1.6 }}>
                {post.content || 'No content'}
              </div>
            </div>

            {post.media_urls && post.media_urls.length > 0 && (
              <div style={{ marginTop: 24 }}>
                <h4>Media</h4>
                <Image.PreviewGroup>
                  <Space wrap>
                    {post.media_urls.map((url, index) => (
                      <Image key={index} width={150} src={url} style={{ borderRadius: 8 }} />
                    ))}
                  </Space>
                </Image.PreviewGroup>
              </div>
            )}
          </Card>
        </Col>

        <Col xs={24} lg={8}>
          <Card style={{ borderRadius: 12 }}>
            <Descriptions title="Statistics" column={1} size="small">
              <Descriptions.Item
                label={
                  <Space>
                    <LikeOutlined style={{ color: '#eb2f96' }} />
                    Likes
                  </Space>
                }
              >
                {post.like_count || 0}
              </Descriptions.Item>
              <Descriptions.Item
                label={
                  <Space>
                    <CommentOutlined style={{ color: '#52c41a' }} />
                    Comments
                  </Space>
                }
              >
                {post.comment_count || 0}
              </Descriptions.Item>
            </Descriptions>
          </Card>
        </Col>
      </Row>
    </div>
  )
}
