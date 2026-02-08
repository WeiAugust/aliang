// ===========================================
// Utility Functions - Date formatting, tag colors, etc.
// ===========================================

// Format date to consistent format
export function formatDate(dateString: string): string {
  const date = new Date(dateString)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  const seconds = String(date.getSeconds()).padStart(2, '0')
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
}

// Tag color configurations - Unified color scheme
export const TAG_COLORS = {
  // Status colors
  active: { color: 'green', text: 'Active' },
  banned: { color: 'red', text: 'Banned' },

  // Visibility colors
  public: { color: 'green', text: 'Public' },
  self_only: { color: 'orange', text: 'Private' },

  // Label colors
  normal: { color: 'default', text: 'Normal' },
  recommended: { color: 'blue', text: 'Recommended' },
  not_recommended: { color: 'red', text: 'Not Recommended' },
} as const

// Role colors
export const ROLE_COLORS = {
  admin: 'purple',
  user: 'blue',
} as const

// Get status tag config
export function getStatusConfig(status: string) {
  return TAG_COLORS[status as keyof typeof TAG_COLORS] || { color: 'default', text: status }
}

// Get role tag color
export function getRoleColor(role: string): string {
  return ROLE_COLORS[role as keyof typeof ROLE_COLORS] || 'blue'
}
