import { useState, useCallback, useEffect } from 'react'
import {
  Card,
  Table,
  Button,
  Space,
  Tag,
  App as AntdApp,
  Avatar,
  Tooltip,
  Dropdown,
  MenuProps,
  Skeleton,
  Alert,
  Input,
} from 'antd'
import {
  EyeOutlined,
  MoreOutlined,
  UserOutlined,
  CheckCircleOutlined,
  SearchOutlined,
  ReloadOutlined,
  UserSwitchOutlined,
  StopOutlined,
} from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'
import { useNavigate } from 'react-router-dom'
import { usersApi } from '@/services/api'
import type { User } from '@/types'

export default function UsersPage() {
  const { message, modal } = AntdApp.useApp()
  const navigate = useNavigate()

  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [hasMore, setHasMore] = useState(true)
  const [offset, setOffset] = useState(0)
  const [searchText, setSearchText] = useState('')
  const limit = 20

  const fetchUsers = useCallback(async (reset = false) => {
    // Allow fetch if reset is true (initial load) or loading is false
    if (!reset && loading) return

    const currentOffset = reset ? 0 : offset
    setLoading(true)
    setError(null)

    try {
      const response = await usersApi.getUsers(currentOffset, limit)
      if (response.success && response.data) {
        let filteredUsers = response.data.items

        // Apply client-side search filter
        if (searchText) {
          const search = searchText.toLowerCase()
          filteredUsers = filteredUsers.filter(
            (user) =>
              user.nickname.toLowerCase().includes(search) ||
              user.phone.includes(search)
          )
        }

        if (reset || currentOffset === 0) {
          setUsers(filteredUsers)
        } else {
          setUsers((prev) => [...prev, ...filteredUsers])
        }
        setHasMore(response.data.has_more)
        setOffset(currentOffset + limit)
      } else {
        setError(response.error?.message || 'Failed to load users')
      }
    } catch (err) {
      setError('Network error - please check your connection')
    } finally {
      setLoading(false)
    }
  }, [offset, limit, loading, searchText])

  // Initial fetch
  useEffect(() => {
    fetchUsers(true)
  }, [searchText])

  const handleBan = (id: number) => {
    modal.confirm({
      title: 'Ban User',
      content: 'Are you sure you want to ban this user? They will not be able to access the platform.',
      okText: 'Ban User',
      okType: 'danger',
      cancelText: 'Cancel',
      async onOk() {
        try {
          const response = await usersApi.banUser(id)
          if (response.success) {
            message.success('User banned successfully')
            fetchUsers(true)
          } else {
            message.error(response.error?.message || 'Failed to ban user')
          }
        } catch {
          message.error('Failed to ban user')
        }
      },
    })
  }

  const handleUnban = (id: number) => {
    modal.confirm({
      title: 'Unban User',
      content: 'Are you sure you want to unban this user?',
      okText: 'Unban',
      cancelText: 'Cancel',
      async onOk() {
        try {
          const response = await usersApi.unbanUser(id)
          if (response.success) {
            message.success('User unbanned successfully')
            fetchUsers(true)
          } else {
            message.error(response.error?.message || 'Failed to unban user')
          }
        } catch {
          message.error('Failed to unban user')
        }
      },
    })
  }

  const handleView = (id: number) => {
    navigate(`/users/${id}`)
  }

  const getStatusTag = (status: string) => {
    const config: Record<string, { color: string; text: string }> = {
      active: { color: 'green', text: 'Active' },
      banned: { color: 'red', text: 'Banned' },
    }
    const { color, text } = config[status] || { color: 'default', text: status }
    return <Tag color={color}>{text}</Tag>
  }

  const columns: ColumnsType<User> = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
      render: (id: number) => <span style={{ color: '#999' }}>#{id}</span>,
    },
    {
      title: 'User',
      key: 'user',
      width: 250,
      render: (_, record) => (
        <Space>
          <Avatar
            src={record.avatar_url}
            icon={<UserOutlined />}
            style={{ backgroundColor: '#667eea' }}
          />
          <div>
            <div style={{ fontWeight: 500 }}>{record.nickname || 'Unknown'}</div>
            <div style={{ fontSize: 12, color: '#999' }}>{record.phone}</div>
          </div>
        </Space>
      ),
    },
    {
      title: 'Role',
      dataIndex: 'role',
      key: 'role',
      width: 100,
      render: (role: string) => (
        <Tag color={role === 'admin' ? 'purple' : 'blue'}>{role}</Tag>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      width: 100,
      render: (status: string) => getStatusTag(status),
    },
    {
      title: 'Posts',
      dataIndex: 'post_count',
      key: 'post_count',
      width: 80,
      sorter: (a, b) => (a.post_count || 0) - (b.post_count || 0),
      render: (count: number) => <span style={{ fontWeight: 500 }}>{count || 0}</span>,
    },
    {
      title: 'Bio',
      dataIndex: 'bio',
      key: 'bio',
      ellipsis: true,
      render: (bio: string) => bio || '-',
    },
    {
      title: 'Joined',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 180,
      render: (date: string) => new Date(date).toLocaleString('zh-CN'),
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 150,
      fixed: 'right',
      render: (_, record) => {
        const items: MenuProps['items'] = [
          {
            key: 'view',
            label: 'View Details',
            icon: <EyeOutlined />,
            onClick: () => handleView(record.id),
          },
          {
            key: 'posts',
            label: 'View Posts',
            icon: <UserSwitchOutlined />,
            onClick: () => navigate(`/posts?user_id=${record.id}`),
          },
          {
            type: 'divider',
          },
          record.status === 'active'
            ? {
                key: 'ban',
                label: 'Ban User',
                icon: <StopOutlined />,
                danger: true,
                onClick: () => handleBan(record.id),
              }
            : {
                key: 'unban',
                label: 'Unban User',
                icon: <CheckCircleOutlined />,
                onClick: () => handleUnban(record.id),
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

  if (loading && users.length === 0) {
    return (
      <div>
        <h1 style={{ marginBottom: 24 }}>User Management</h1>
        <Card>
          <Skeleton active paragraph={{ rows: 10 }} />
        </Card>
      </div>
    )
  }

  if (error && users.length === 0) {
    return (
      <div>
        <h1 style={{ marginBottom: 24 }}>User Management</h1>
        <Alert
          type="error"
          message="Failed to load users"
          description={error}
          showIcon
          action={
            <Button onClick={() => fetchUsers(true)}>Retry</Button>
          }
        />
      </div>
    )
  }

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <h1 style={{ margin: 0, fontSize: 24, fontWeight: 600 }}>User Management</h1>
        <Space>
          <Input
            placeholder="Search by nickname or phone"
            prefix={<SearchOutlined style={{ color: '#999' }} />}
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            style={{ width: 250 }}
            allowClear
          />
          <Button
            icon={<ReloadOutlined />}
            onClick={() => fetchUsers(true)}
            loading={loading}
          >
            Refresh
          </Button>
        </Space>
      </div>

      <Card style={{ borderRadius: 12 }} styles={{ body: { padding: 0 } }}>
        <Table
          columns={columns}
          dataSource={users}
          rowKey="id"
          loading={loading && users.length > 0}
          scroll={{ x: 1200 }}
          pagination={{
            pageSize: limit,
            showSizeChanger: true,
            showTotal: (total) => `Total ${total} users`,
            onChange: (page, pageSize) => {
              const newOffset = (page - 1) * pageSize
              if (newOffset >= offset && hasMore) {
                fetchUsers()
              }
            },
          }}
        />
      </Card>
    </div>
  )
}
