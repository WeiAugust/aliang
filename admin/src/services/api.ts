// ===========================================
// Admin API Service - Backend Admin API endpoints
// ===========================================

import apiClient from './client'
import type {
  ApiResponse,
  LoginRequest,
  LoginResponse,
  DashboardStats,
  PostListResponse,
  UpdateVisibilityRequest,
  UpdateLabelRequest,
  UserListResponse,
  UserDetail,
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
    limit = 20
  ): Promise<ApiResponse<PostListResponse>> => {
    const response = await apiClient.get('/admin/posts', {
      params: { offset, limit },
    })
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
    limit = 20
  ): Promise<ApiResponse<UserListResponse>> => {
    const response = await apiClient.get('/admin/users', {
      params: { offset, limit },
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
