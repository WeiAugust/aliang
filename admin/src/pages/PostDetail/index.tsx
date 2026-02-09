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
  List,
  Avatar,
  Typography,
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
import type { Post, PostComment } from '@/types'
import { formatDate, getStatusConfig } from '@/utils'

function normalizeRemoteURL(value: string): string {
  const trimmed = value.trim()
  if (!trimmed) return value
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed
  if (trimmed.startsWith('//')) return `http:${trimmed}`
  return `http://${trimmed}`
}

export default function PostDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [post, setPost] = useState<Post | null>(null)
  const [comments, setComments] = useState<PostComment[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchPost = async () => {
      if (!id) return

      try {
        setLoading(true)
        setError(null)
        const [postResponse, commentsResponse] = await Promise.all([
          postsApi.getPostById(Number(id)),
          postsApi.getPostComments(Number(id), 0, 100),
        ])

        if (postResponse.success && postResponse.data) {
          const normalizedMediaUrls = postResponse.data.media_urls?.map(normalizeRemoteURL)
          setPost({
            ...postResponse.data,
            media_urls: normalizedMediaUrls,
          })

          if (commentsResponse.success && commentsResponse.data) {
            setComments(commentsResponse.data.items || [])
          } else {
            setComments([])
          }
        } else {
          setError(postResponse.error?.message || 'Post not found')
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
          className="detail-back-button"
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
        className="detail-back-button"
      >
        Back to Posts
      </Button>

      <Row gutter={[16, 16]}>
        <Col xs={24} lg={16}>
          <Card className="detail-card">
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
              <h4 className="detail-section-title">Content</h4>
              <div className="content-pre">
                {post.content || 'No content'}
              </div>
            </div>

            {post.media_urls && post.media_urls.length > 0 && (
              <div style={{ marginTop: 24 }}>
                <h4 className="detail-section-title">Media</h4>
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
          <Card className="detail-card">
            <Descriptions title="Statistics" column={1} size="small">
              <Descriptions.Item
                label={
                  <Space>
                    <LikeOutlined className="stat-value-accent" />
                    Likes
                  </Space>
                }
              >
                <span className="stat-value-accent">{post.like_count || 0}</span>
              </Descriptions.Item>
              <Descriptions.Item
                label={
                  <Space>
                    <CommentOutlined className="stat-value-success" />
                    Comments
                  </Space>
                }
              >
                <span className="stat-value-success">{post.comment_count || 0}</span>
              </Descriptions.Item>
            </Descriptions>
          </Card>

          <Card title={`Comments (${comments.length})`} className="detail-card" style={{ marginTop: 16 }}>
            {comments.length === 0 ? (
              <Typography.Text type="secondary">No comments yet</Typography.Text>
            ) : (
              <List
                dataSource={comments}
                renderItem={(comment) => (
                  <List.Item>
                    <List.Item.Meta
                      avatar={
                        <Avatar>
                          {comment.user?.nickname?.charAt(0)?.toUpperCase() || '#'}
                        </Avatar>
                      }
                      title={
                        <Space size={8}>
                          <span>{comment.user?.nickname || `User #${comment.user_id}`}</span>
                          <Typography.Text type="secondary" style={{ fontSize: 12 }}>
                            {formatDate(comment.created_at)}
                          </Typography.Text>
                        </Space>
                      }
                      description={comment.content}
                    />
                  </List.Item>
                )}
              />
            )}
          </Card>
        </Col>
      </Row>
    </div>
  )
}
