import { useState, useCallback, useEffect } from 'react'
import {
  Card,
  Table,
  Button,
  Space,
  Tag,
  App as AntdApp,
  Tooltip,
  Dropdown,
  MenuProps,
  Skeleton,
  Alert,
  Input,
  Select,
} from 'antd'
import {
  EyeOutlined,
  DeleteOutlined,
  MoreOutlined,
  LockOutlined,
  UnlockOutlined,
  StarOutlined,
  StarFilled,
  ReloadOutlined,
  SearchOutlined,
} from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'
import { useNavigate } from 'react-router-dom'
import { postsApi } from '@/services/api'
import type { Post } from '@/types'
import { formatDate, getStatusConfig } from '@/utils'

export default function PostsPage() {
  const { message, modal } = AntdApp.useApp()
  const navigate = useNavigate()

  const [posts, setPosts] = useState<Post[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [hasMore, setHasMore] = useState(true)
  const [offset, setOffset] = useState(0)
  const [total, setTotal] = useState(0)
  const limit = 20

  // Filter states
  const [searchText, setSearchText] = useState('')
  const [visibilityFilter, setVisibilityFilter] = useState<'public' | 'self_only' | undefined>(undefined)
  const [labelFilter, setLabelFilter] = useState<'normal' | 'recommended' | 'not_recommended' | undefined>(undefined)

  const fetchPosts = useCallback(async (reset = false) => {
    if (!reset && loading) return

    const currentOffset = reset ? 0 : offset
    setLoading(true)
    setError(null)

    try {
      const response = await postsApi.getPosts(currentOffset, limit, undefined, {
        visibility: visibilityFilter,
        label: labelFilter,
      })
      if (response.success && response.data) {
        let items = response.data.items || []

        // Apply client-side search filter for title
        if (searchText) {
          const search = searchText.toLowerCase()
          items = items.filter((post) =>
            post.title.toLowerCase().includes(search)
          )
        }

        if (reset || currentOffset === 0) {
          setPosts(items)
        } else {
          setPosts((prev) => [...prev, ...items])
        }
        setHasMore(response.data.has_more ?? false)
        setTotal(response.data.total || 0)
        setOffset(currentOffset + limit)
      } else {
        setError(response.error?.message || 'Failed to load posts')
      }
    } catch {
      setError('Network error - please check your connection')
    } finally {
      setLoading(false)
    }
  }, [offset, limit, loading, searchText, visibilityFilter, labelFilter])

  // Fetch when filters change
  useEffect(() => {
    fetchPosts(true)
  }, [searchText, visibilityFilter, labelFilter])

  const handleDelete = (id: number) => {
    modal.confirm({
      title: 'Delete Post',
      content: 'Are you sure you want to delete this post? This action cannot be undone.',
      okText: 'Delete',
      okType: 'danger',
      cancelText: 'Cancel',
      async onOk() {
        try {
          const response = await postsApi.deletePost(id)
          if (response.success) {
            message.success('Post deleted successfully')
            fetchPosts(true)
          } else {
            message.error(response.error?.message || 'Failed to delete post')
          }
        } catch {
          message.error('Failed to delete post')
        }
      },
    })
  }

  const handleVisibilityChange = async (id: number, visibility: 'public' | 'self_only') => {
    try {
      const response = await postsApi.updateVisibility(id, { visibility })
      if (response.success) {
        message.success(`Post visibility set to ${visibility}`)
        fetchPosts(true)
      } else {
        message.error(response.error?.message || 'Failed to update visibility')
      }
    } catch {
      message.error('Failed to update visibility')
    }
  }

  const handleLabelChange = async (id: number, label: 'normal' | 'recommended' | 'not_recommended') => {
    try {
      const response = await postsApi.updateLabel(id, { label })
      if (response.success) {
        message.success(`Post label updated to ${label}`)
        fetchPosts(true)
      } else {
        message.error(response.error?.message || 'Failed to update label')
      }
    } catch {
      message.error('Failed to update label')
    }
  }

  const handleView = (id: number) => {
    navigate(`/posts/${id}`)
  }

  const getVisibilityTag = (visibility: string) => {
    const { color, text } = getStatusConfig(visibility)
    const icon = visibility === 'public' ? <UnlockOutlined /> : <LockOutlined />
    return (
      <Tag color={color} icon={icon}>
        {text}
      </Tag>
    )
  }

  const getLabelTag = (label: string) => {
    const { color, text } = getStatusConfig(label)
    const icon =
      label === 'recommended' ? (
        <StarFilled />
      ) : label === 'not_recommended' ? (
        <StarOutlined />
      ) : null
    return (
      <Tag color={color} icon={icon}>
        {text}
      </Tag>
    )
  }

  const columns: ColumnsType<Post> = [
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
      render: (title: string) => <span style={{ fontWeight: 500 }}>{title || 'Untitled'}</span>,
    },
    {
      title: 'Author ID',
      dataIndex: 'user_id',
      key: 'user_id',
      width: 100,
      render: (id: number) => <span>#{id}</span>,
    },
    {
      title: 'Visibility',
      dataIndex: 'visibility',
      key: 'visibility',
      width: 120,
      render: (visibility: string) => getVisibilityTag(visibility),
    },
    {
      title: 'Label',
      dataIndex: 'label',
      key: 'label',
      width: 140,
      render: (label: string) => getLabelTag(label),
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
    {
      title: 'Actions',
      key: 'actions',
      width: 200,
      fixed: 'right',
      render: (_, record) => {
        const items: MenuProps['items'] = [
          {
            key: 'visibility',
            label: 'Change Visibility',
            children: [
              {
                key: 'public',
                label: 'Public',
                icon: <UnlockOutlined />,
                onClick: () => handleVisibilityChange(record.id, 'public'),
              },
              {
                key: 'private',
                label: 'Private (Self Only)',
                icon: <LockOutlined />,
                onClick: () => handleVisibilityChange(record.id, 'self_only'),
              },
            ],
          },
          {
            key: 'label',
            label: 'Change Label',
            children: [
              {
                key: 'normal',
                label: 'Normal',
                onClick: () => handleLabelChange(record.id, 'normal'),
              },
              {
                key: 'recommended',
                label: 'Recommended',
                onClick: () => handleLabelChange(record.id, 'recommended'),
              },
              {
                key: 'not_recommended',
                label: 'Not Recommended',
                onClick: () => handleLabelChange(record.id, 'not_recommended'),
              },
            ],
          },
          {
            type: 'divider',
          },
          {
            key: 'delete',
            label: 'Delete',
            danger: true,
            icon: <DeleteOutlined />,
            onClick: () => handleDelete(record.id),
          },
        ]

        return (
          <Space>
            <Tooltip title="View Details">
              <Button
                type="text"
                icon={<EyeOutlined />}
                onClick={() => handleView(record.id)}
              />
            </Tooltip>
            <Dropdown menu={{ items }} trigger={['click']}>
              <Button type="text" icon={<MoreOutlined />} />
            </Dropdown>
          </Space>
        )
      },
    },
  ]

  if (loading && posts.length === 0) {
    return (
      <div>
        <h1 style={{ marginBottom: 24 }}>Content Management</h1>
        <Card>
          <Skeleton active paragraph={{ rows: 10 }} />
        </Card>
      </div>
    )
  }

  if (error && posts.length === 0) {
    return (
      <div>
        <h1 style={{ marginBottom: 24 }}>Content Management</h1>
        <Alert
          type="error"
          message="Failed to load posts"
          description={error}
          showIcon
          action={
            <Button onClick={() => fetchPosts(true)}>Retry</Button>
          }
        />
      </div>
    )
  }

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <h1 style={{ margin: 0, fontSize: 24, fontWeight: 600 }}>Content Management</h1>
        <Button
          icon={<ReloadOutlined />}
          onClick={() => fetchPosts(true)}
          loading={loading}
        >
          Refresh
        </Button>
      </div>

      <Card style={{ borderRadius: 12, marginBottom: 16 }} styles={{ body: { padding: 16 } }}>
        <Space wrap>
          <Input
            placeholder="Search by title"
            prefix={<SearchOutlined style={{ color: '#999' }} />}
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            style={{ width: 250 }}
            allowClear
          />
          <Select
            placeholder="Visibility"
            allowClear
            style={{ width: 140 }}
            value={visibilityFilter}
            onChange={setVisibilityFilter}
            options={[
              { value: 'public', label: 'Public' },
              { value: 'self_only', label: 'Private' },
            ]}
          />
          <Select
            placeholder="Label"
            allowClear
            style={{ width: 160 }}
            value={labelFilter}
            onChange={setLabelFilter}
            options={[
              { value: 'normal', label: 'Normal' },
              { value: 'recommended', label: 'Recommended' },
              { value: 'not_recommended', label: 'Not Recommended' },
            ]}
          />
        </Space>
      </Card>

      <Card style={{ borderRadius: 12 }} styles={{ body: { padding: 0 } }}>
        <Table
          columns={columns}
          dataSource={posts}
          rowKey="id"
          loading={loading && posts.length > 0}
          scroll={{ x: 1000 }}
          pagination={{
            total: total,
            pageSize: limit,
            showSizeChanger: true,
            showTotal: (total) => `Total ${total} posts`,
            onChange: (page, pageSize) => {
              const newOffset = (page - 1) * pageSize
              if (newOffset >= offset && hasMore) {
                fetchPosts()
              }
            },
          }}
        />
      </Card>
    </div>
  )
}
