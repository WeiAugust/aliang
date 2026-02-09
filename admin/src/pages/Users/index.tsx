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
  Select,
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
import { formatDate, getStatusConfig, getRoleColor } from '@/utils'

export default function UsersPage() {
  const { message, modal } = AntdApp.useApp()
  const navigate = useNavigate()

  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [hasMore, setHasMore] = useState(true)
  const [offset, setOffset] = useState(0)
  const [searchText, setSearchText] = useState('')
  const [total, setTotal] = useState(0)
  const [statusFilter, setStatusFilter] = useState<'active' | 'banned' | undefined>(undefined)
  const [roleFilter, setRoleFilter] = useState<'user' | 'admin' | undefined>(undefined)
  const limit = 20

  const fetchUsers = useCallback(async (reset = false) => {
    if (!reset && loading) return

    const currentOffset = reset ? 0 : offset
    setLoading(true)
    setError(null)

    try {
      const response = await usersApi.getUsers(currentOffset, limit, {
        status: statusFilter,
        role: roleFilter,
      })
      if (response.success && response.data) {
        let filteredUsers = response.data.items

        if (searchText) {
          const search = searchText.toLowerCase()
          filteredUsers = filteredUsers.filter(
            (user) =>
              (user.nickname && user.nickname.toLowerCase().includes(search)) ||
              user.phone.includes(search)
          )
        }

        if (reset || currentOffset === 0) {
          setUsers(filteredUsers)
        } else {
          setUsers((prev) => [...prev, ...filteredUsers])
        }
        setHasMore(response.data.has_more)
        setTotal(response.data.total || 0)
        setOffset(currentOffset + limit)
      } else {
        setError(response.error?.message || 'Failed to load users')
      }
    } catch {
      setError('Network error - please check your connection')
    } finally {
      setLoading(false)
    }
  }, [offset, limit, loading, searchText, statusFilter, roleFilter])

  useEffect(() => {
    fetchUsers(true)
  }, [searchText, statusFilter, roleFilter])

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
      content: 'Are you sure you want to unban this user? They will be able to access the platform again.',
      okText: 'Unban User',
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
    const { color, text } = getStatusConfig(status)
    return <Tag color={color}>{text}</Tag>
  }

  const columns: ColumnsType<User> = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
      render: (id: number) => <span className="muted-id">#{id}</span>,
    },
    {
      title: 'User',
      key: 'user',
      width: 250,
      render: (_, record) => (
        <Space>
          <Avatar
            src={record.avatar_url || undefined}
            icon={!record.avatar_url ? <UserOutlined /> : undefined}
            style={{ backgroundColor: '#4f6ef7' }}
          />
          <div>
            <div className="table-title-cell">{record.nickname || 'Unknown'}</div>
            <div className="table-secondary-cell" style={{ fontSize: 12 }}>{record.phone}</div>
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
        <Tag color={getRoleColor(role)}>{role}</Tag>
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
      showSorterTooltip: { title: 'Click to sort by post count' },
      render: (count: number) => <span className="table-title-cell">{count || 0}</span>,
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
      render: (date: string) => formatDate(date),
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
                className="table-action-btn"
              />
            </Tooltip>
            <Dropdown menu={{ items }} trigger={['click']}>
              <Button type="text" icon={<MoreOutlined />} className="table-action-btn" />
            </Dropdown>
          </Space>
        )
      },
    },
  ]

  if (loading && users.length === 0) {
    return (
      <div>
        <div className="page-header">
          <div>
            <h1 className="page-title">User Management</h1>
            <p className="page-title-subtle">Manage user roles, status and activity</p>
          </div>
        </div>
        <Card className="page-card">
          <Skeleton active paragraph={{ rows: 10 }} />
        </Card>
      </div>
    )
  }

  if (error && users.length === 0) {
    return (
      <div>
        <div className="page-header">
          <div>
            <h1 className="page-title">User Management</h1>
            <p className="page-title-subtle">Manage user roles, status and activity</p>
          </div>
        </div>
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
      <div className="page-header">
        <div>
          <h1 className="page-title">User Management</h1>
          <p className="page-title-subtle">Manage user roles, status and activity</p>
        </div>
        <Space>
          <Button
            icon={<ReloadOutlined />}
            onClick={() => fetchUsers(true)}
            loading={loading}
          >
            Refresh
          </Button>
        </Space>
      </div>

      <Card className="page-card filter-card" styles={{ body: { padding: 16 } }}>
        <Space wrap>
          <Input
            placeholder="Search by nickname or phone"
            prefix={<SearchOutlined className="field-prefix-icon" />}
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            style={{ width: 250 }}
            allowClear
          />
          <Select
            placeholder="Status"
            allowClear
            style={{ width: 140 }}
            value={statusFilter}
            onChange={setStatusFilter}
            options={[
              { value: 'active', label: 'Active' },
              { value: 'banned', label: 'Banned' },
            ]}
          />
          <Select
            placeholder="Role"
            allowClear
            style={{ width: 120 }}
            value={roleFilter}
            onChange={setRoleFilter}
            options={[
              { value: 'user', label: 'User' },
              { value: 'admin', label: 'Admin' },
            ]}
          />
        </Space>
      </Card>

      <Card className="page-card table-card" styles={{ body: { padding: 0 } }}>
        <Table
          columns={columns}
          dataSource={users}
          rowKey="id"
          loading={loading && users.length > 0}
          scroll={{ x: 1200 }}
          pagination={{
            total: total,
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
