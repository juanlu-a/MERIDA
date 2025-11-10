import { apiClient } from './api'
import type { Facility, PlotMetadata, CreateFacilityRequest } from '@/types'

export const facilityService = {
  getFacilities: async (): Promise<Facility[]> => {
    const response = await apiClient.get('/facilities/')
    return response.data.facilities || []
  },
  getFacility: async (facilityId: string): Promise<Facility> => {
    const response = await apiClient.get(`/facilities/${facilityId}`)
    return response.data
  },
  createFacility: async (data: CreateFacilityRequest): Promise<any> => {
    const response = await apiClient.post('/facilities/', data)
    return response.data
  },
  getFacilityPlots: async (facilityId: string): Promise<PlotMetadata[]> => {
    const response = await apiClient.get(`/plots/facility/${facilityId}`)
    return response.data.plots || []
  },
  getFacilityResponsibles: async (facilityId: string) => {
    const response = await apiClient.get(`/facilities/${facilityId}/responsibles`)
    return response.data
  },
  updateFacilityResponsibles: async (facilityId: string, responsibles: string[]) => {
    const response = await apiClient.put(`/facilities/${facilityId}/responsibles`, { responsibles })
    return response.data
  },
}
