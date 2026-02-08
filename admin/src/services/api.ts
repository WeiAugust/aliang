// ===========================================
// Admin API Service - Backend Admin API endpoints
// ===========================================

import apiClient from './client'
import type {
  ApiResponse,
  LoginRequest,
  LoginResponse,
  DashboardStats,
  Post,
  PostListResponse,
  UpdateVisibilityRequest,
  UpdateLabelRequest,
  UserListResponse,
  UserDetail,
  PostFilters,
  UserFilters,
} from '@/types'

// Auth API
export const authApi = {
  login: async (data: LoginRequest): Promise<ApiResponse<LoginResponse>> => {
    const response = await apiClient.post('/admin/auth/login', data)
    return response.data
  },

  logout: async (): Promise<void> => {
    localStorage.removeItem('admin_token')
  },
}

// Dashboard Stats API
export const statsApi = {
  getStats: async (): Promise<ApiResponse<DashboardStats>> => {
    const response = await apiClient.get('/admin/stats')
    return response.data
  },
}

// Posts API
export const postsApi = {
  // Get all posts with pagination
  getPosts: async (
    offset = 0,
    limit = 20,
    postId?: number,
    filters?: PostFilters
  ): Promise<ApiResponse<PostListResponse>> => {
    const params: Record<string, number | string | undefined> = { offset, limit }
    if (postId) {
      params.id = postId
    }
    if (filters) {
      if (filters.visibility) params.visibility = filters.visibility
      if (filters.label) params.label = filters.label
      if (filters.user_id) params.user_id = filters.user_id
    }
    const response = await apiClient.get('/admin/posts', {
      params,
    })
    return response.data
  },

  // Get single post by ID
  getPostById: async (id: number): Promise<ApiResponse<Post | null>> => {
    const response = await apiClient.get(`/admin/posts/${id}`)
    return response.data
  },

  // Update post visibility
  updateVisibility: async (
    id: number,
    data: UpdateVisibilityRequest
  ): Promise<ApiResponse<null>> => {
    const response = await apiClient.put(`/admin/posts/${id}/visibility`, data)
    return response.data
  },

  // Update post label
  updateLabel: async (
    id: number,
    data: UpdateLabelRequest
  ): Promise<ApiResponse<null>> => {
    const response = await apiClient.put(`/admin/posts/${id}/label`, data)
    return response.data
  },

  // Delete post
  deletePost: async (id: number): Promise<ApiResponse<null>> => {
    const response = await apiClient.delete(`/admin/posts/${id}`)
    return response.data
  },
}

// Users API
export const usersApi = {
  // Get all users with pagination
  getUsers: async (
    offset = 0,
    limit = 20,
    filters?: UserFilters
  ): Promise<ApiResponse<UserListResponse>> => {
    const params: Record<string, number | string | undefined> = { offset, limit }
    if (filters) {
      if (filters.status) params.status = filters.status
      if (filters.role) params.role = filters.role
    }
    const response = await apiClient.get('/admin/users', {
      params,
    })
    return response.data
  },

  // Get user detail with posts
  getUserDetail: async (id: number): Promise<ApiResponse<UserDetail>> => {
    const response = await apiClient.get(`/admin/users/${id}`)
    return response.data
  },

  // Ban user
  banUser: async (id: number): Promise<ApiResponse<null>> => {
    const response = await apiClient.put(`/admin/users/${id}/ban`)
    return response.data
  },

  // Unban user
  unbanUser: async (id: number): Promise<ApiResponse<null>> => {
    const response = await apiClient.put(`/admin/users/${id}/unban`)
    return response.data
  },
}
