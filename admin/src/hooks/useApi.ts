// ===========================================
// Custom React Hooks for Admin Panel
// ===========================================

import { useState, useCallback, useEffect } from 'react'
import type { ApiResponse } from '@/types'

// Generic fetch hook
export function useFetch<T>(
  fetchFn: () => Promise<ApiResponse<T>>,
  autoFetch = true
) {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(autoFetch)
  const [error, setError] = useState<string | null>(null)

  const refetch = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await fetchFn()
      if (response.success && response.data) {
        setData(response.data)
      } else {
        setError(response.error?.message || 'Unknown error')
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Network error')
    } finally {
      setLoading(false)
    }
  }, [fetchFn])

  useEffect(() => {
    if (autoFetch) {
      refetch()
    }
  }, [autoFetch, refetch])

  return { data, loading, error, refetch }
}

// Pagination hook
export function usePagination<T>(
  fetchFn: (offset: number, limit: number) => Promise<ApiResponse<{ items: T[]; has_more: boolean }>>
) {
  const [data, setData] = useState<T[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [hasMore, setHasMore] = useState(true)
  const [offset, setOffset] = useState(0)
  const limit = 20

  const loadMore = useCallback(async (reset = false) => {
    if (loading) return

    const currentOffset = reset ? 0 : offset
    setLoading(true)
    setError(null)

    try {
      const response = await fetchFn(currentOffset, limit)
      const data = response.data
      if (response.success && data) {
        if (reset || currentOffset === 0) {
          setData(data.items || [])
        } else {
          setData((prev) => [...(prev || []), ...(data.items || [])])
        }
        setHasMore(data.has_more ?? false)
        setOffset(currentOffset + limit)
      } else {
        setError(response.error?.message || 'Failed to load data')
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Network error')
    } finally {
      setLoading(false)
    }
  }, [fetchFn, offset, limit, loading])

  const refresh = useCallback(() => {
    setOffset(0)
    setHasMore(true)
    loadMore(true)
  }, [loadMore])

  useEffect(() => {
    loadMore(true)
  }, [])

  return { data, loading, error, hasMore, loadMore, refresh }
}

// Optimistic update hook for mutations
export function useOptimisticMutation<T, R>(
  mutationFn: (data: T) => Promise<ApiResponse<R>>,
  onSuccess?: (data: R) => void,
  onError?: (error: string) => void
) {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const mutate = useCallback(async (data: T) => {
    setLoading(true)
    setError(null)

    try {
      const response = await mutationFn(data)
      if (response.success) {
        onSuccess?.(response.data!)
        return response.data
      } else {
        setError(response.error?.message || 'Mutation failed')
        onError?.(response.error?.message || 'Mutation failed')
        throw new Error(response.error?.message)
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Network error'
      setError(errorMsg)
      onError?.(errorMsg)
      throw err
    } finally {
      setLoading(false)
    }
  }, [mutationFn, onSuccess, onError])

  return { mutate, loading, error }
}
