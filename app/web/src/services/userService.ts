import { apiClient } from './api'
import { User } from '@/types'

export const userService = {
  // Get user by ID
  getUser: async (userId: string): Promise<User> => {
    const response = await apiClient.get(`/users/${userId}`)
    return response.data
  },

  // Update user profile
  updateUser: async (userId: string, data: Partial<User>): Promise<User> => {
    const response = await apiClient.put(`/users/${userId}`, data)
    return response.data
  },
}
