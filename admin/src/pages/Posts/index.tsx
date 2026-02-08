import { Card, Table, Button, Space, Tag, message } from 'antd'
import { DeleteOutlined, EyeOutlined } from '@ant-design/icons'
import type { ColumnsType } from 'antd/es/table'

interface Post {
  id: string
  title: string
  author: string
  visibility: 'public' | 'self_only'
  status: 'normal' | 'recommended' | 'not_recommended'
  createdAt: string
}

export default function PostsPage() {
  // TODO: Fetch real data from API
  const posts: Post[] = [
    {
      id: '1',
      title: 'Sample Post 1',
      author: 'User 1',
      visibility: 'public',
      status: 'normal',
      createdAt: '2024-01-01',
    },
    {
      id: '2',
      title: 'Sample Post 2',
      author: 'User 2',
      visibility: 'public',
      status: 'recommended',
      createdAt: '2024-01-02',
    },
  ]

  const handleDelete = (id: string) => {
    message.success(`Post ${id} deleted`)
    // TODO: Implement actual delete API call
  }

  const handleView = (id: string) => {
    message.info(`Viewing post ${id}`)
    // TODO: Navigate to post detail page
  }

  const columns: ColumnsType<Post> = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: 'Title',
      dataIndex: 'title',
      key: 'title',
    },
    {
      title: 'Author',
      dataIndex: 'author',
      key: 'author',
    },
    {
      title: 'Visibility',
      dataIndex: 'visibility',
      key: 'visibility',
      render: (visibility: string) => (
        <Tag color={visibility === 'public' ? 'green' : 'orange'}>
          {visibility}
        </Tag>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => {
        const color = status === 'recommended' ? 'blue' : status === 'not_recommended' ? 'red' : 'default'
        return <Tag color={color}>{status}</Tag>
      },
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
            onClick={() => handleView(record.id)}
          >
            View
          </Button>
          <Button
            type="link"
            danger
            icon={<DeleteOutlined />}
            onClick={() => handleDelete(record.id)}
          >
            Delete
          </Button>
        </Space>
      ),
    },
  ]

  return (
    <div>
      <h1 style={{ marginBottom: 24 }}>Content Management</h1>

      <Card>
        <Table
          columns={columns}
          dataSource={posts}
          rowKey="id"
          pagination={{
            pageSize: 20,
            showSizeChanger: true,
            showTotal: (total) => `Total ${total} posts`,
          }}
        />
      </Card>
    </div>
  )
}
