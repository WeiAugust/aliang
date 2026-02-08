import { Card, Table, Button, Space, Tag } from 'antd'
import { EyeOutlined } from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'

interface User {
  id: string
  nickname: string
  phone: string
  postCount: number
  status: 'active' | 'banned'
  createdAt: string
}

export default function UsersPage() {
  // TODO: Fetch real data from API
  const users: User[] = [
    {
      id: '1',
      nickname: 'User 1',
      phone: '138****1234',
      postCount: 10,
      status: 'active',
      createdAt: '2024-01-01',
    },
    {
      id: '2',
      nickname: 'User 2',
      phone: '139****5678',
      postCount: 5,
      status: 'active',
      createdAt: '2024-01-02',
    },
  ]

  const columns: ColumnsType<User> = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: 'Nickname',
      dataIndex: 'nickname',
      key: 'nickname',
    },
    {
      title: 'Phone',
      dataIndex: 'phone',
      key: 'phone',
    },
    {
      title: 'Post Count',
      dataIndex: 'postCount',
      key: 'postCount',
      sorter: (a, b) => a.postCount - b.postCount,
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => (
        <Tag color={status === 'active' ? 'green' : 'red'}>
          {status}
        </Tag>
      ),
    },
    {
      title: 'Created At',
      dataIndex: 'createdAt',
      key: 'createdAt',
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_, record) => (
        <Space>
          <Button
            type="link"
            icon={<EyeOutlined />}
            onClick={() => console.log('View user', record.id)}
          >
            View
          </Button>
        </Space>
      ),
    },
  ]

  return (
    <div>
      <h1 style={{ marginBottom: 24 }}>User Management</h1>

      <Card>
        <Table
          columns={columns}
          dataSource={users}
          rowKey="id"
          pagination={{
            pageSize: 20,
            showSizeChanger: true,
            showTotal: (total) => `Total ${total} users`,
          }}
        />
      </Card>
    </div>
  )
}
