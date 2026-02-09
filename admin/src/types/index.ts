// ===========================================
// Admin Types - Unified Type Definitions
// ===========================================

// API Response wrapper
export interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: {
    code: string
    message: string
  }
  message?: string
}

// Pagination meta
export interface PaginationMeta {
  total?: number
  page?: number
  limit?: number
  has_more?: boolean
}

// Admin User
export interface AdminUser {
  id: number
  username: string
  role: string
  avatar_url?: string
}

// Login request/response
export interface LoginRequest {
  username: string
  password: string
}

export interface LoginResponse {
  token: string
  admin: AdminUser
}

// Dashboard Statistics
export interface DashboardStats {
  total_users: number
  total_posts: number
  total_likes: number
  total_comments: number
  daily_active_users: number
  daily_new_posts: number
}

// Post (for admin)
export interface Post {
  id: number
  title: string
  content: string
  visibility: 'public' | 'self_only'
  label: 'normal' | 'recommended' | 'not_recommended'
  user_id: number
  author?: string
  created_at: string
  updated_at?: string
  like_count?: number
  comment_count?: number
  media_urls?: string[]
  comments?: PostComment[]
}

export interface PostCommentUser {
  id: number
  nickname: string
  avatar_url?: string
}

export interface PostComment {
  id: number
  user_id: number
  post_id: number
  content: string
  created_at: string
  user?: PostCommentUser
}

export interface CommentListResponse {
  items: PostComment[]
  has_more: boolean
}

// User (for admin)
export interface User {
  id: number
  phone: string
  nickname: string
  avatar_url?: string
  bio?: string
  status: 'active' | 'banned'
  role: 'user' | 'admin'
  post_count?: number
  like_count?: number
  comment_count?: number
  created_at: string
}

// User detail with posts (for admin user detail page)
export interface UserDetail extends User {
  recent_posts: Post[]
}

// Post moderation requests
export interface UpdateVisibilityRequest {
  visibility: 'public' | 'self_only'
}

export interface UpdateLabelRequest {
  label: 'normal' | 'recommended' | 'not_recommended'
}

// Post list response
export interface PostListResponse {
  items: Post[]
  has_more: boolean
  total?: number
}

// User list response
export interface UserListResponse {
  items: User[]
  has_more: boolean
  total?: number
}

// Filter types for admin operations
export interface PostFilters {
  visibility?: 'public' | 'self_only'
  label?: 'normal' | 'recommended' | 'not_recommended'
  user_id?: number
}

export interface UserFilters {
  status?: 'active' | 'banned'
  role?: 'user' | 'admin'
}
