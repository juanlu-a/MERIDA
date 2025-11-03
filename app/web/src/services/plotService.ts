import { apiClient } from './api'
import { PlotMetadata, PlotState, CreatePlotRequest, UpdatePlotRequest } from '@/types'

export const plotService = {
  // Get all plots for a user
  getPlots: async (userId: string): Promise<PlotMetadata[]> => {
    const response = await apiClient.get(`/users/${userId}/plots`)
    return response.data
  },

  // Get a specific plot
  getPlot: async (plotId: string): Promise<PlotMetadata> => {
    const response = await apiClient.get(`/plot/${plotId}`)
    return response.data
  },

  // Create a new plot
  createPlot: async (data: CreatePlotRequest): Promise<PlotMetadata> => {
    const response = await apiClient.post('/plot', data)
    return response.data
  },

  // Update a plot
  updatePlot: async (plotId: string, data: UpdatePlotRequest): Promise<PlotMetadata> => {
    const response = await apiClient.put(`/plot/${plotId}`, data)
    return response.data
  },

  // Delete a plot
  deletePlot: async (plotId: string): Promise<void> => {
    await apiClient.delete(`/plot/${plotId}`)
  },

  // Get plot state/sensor data
  getPlotState: async (plotId: string): Promise<PlotState> => {
    const response = await apiClient.get(`/plot/${plotId}/state`)
    return response.data
  },

  // Get historical sensor data
  getPlotHistory: async (
    plotId: string,
    startDate?: string,
    endDate?: string
  ): Promise<PlotState[]> => {
    const params = new URLSearchParams()
    if (startDate) params.append('start_date', startDate)
    if (endDate) params.append('end_date', endDate)

    const response = await apiClient.get(`/plot/${plotId}/history?${params.toString()}`)
    return response.data
  },
}
