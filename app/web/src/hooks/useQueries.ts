import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { plotService } from '@/services/plotService'
import { userService } from '@/services/userService'
import { facilityService } from '@/services/facilityService'
import { irrigationService } from '@/services/irrigationService'
import { speciesService } from '@/services/speciesService'
import type { CreatePlotRequest, UpdatePlotRequest, CreateFacilityRequest } from '@/types'

// User queries
export function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => userService.getUser(userId),
    enabled: !!userId,
  })
}

// Plot queries
export function usePlots(userId: string) {
  return useQuery({
    queryKey: ['plots', userId],
    queryFn: () => plotService.getPlots(userId),
    enabled: !!userId,
  })
}

export function usePlot(plotId: string) {
  return useQuery({
    queryKey: ['plot', plotId],
    queryFn: () => plotService.getPlot(plotId),
    enabled: !!plotId,
  })
}

export function usePlotState(plotId: string) {
  return useQuery({
    queryKey: ['plotState', plotId],
    queryFn: () => plotService.getPlotState(plotId),
    enabled: !!plotId,
    refetchInterval: 900000, // Refetch every 15 minutes
  })
}

export function usePlotHistory(plotId: string, startDate?: string, endDate?: string) {
  return useQuery({
    queryKey: ['plotHistory', plotId, startDate, endDate],
    queryFn: () => plotService.getPlotHistory(plotId, startDate, endDate),
    enabled: !!plotId,
    refetchInterval: 900000, // Refetch every 15 minutes
  })
}

// Plot mutations
export function useCreatePlot() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: CreatePlotRequest) => plotService.createPlot(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plots'] })
    },
  })
}

export function useUpdatePlot() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ plotId, data }: { plotId: string; data: UpdatePlotRequest }) =>
      plotService.updatePlot(plotId, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['plot', variables.plotId] })
      queryClient.invalidateQueries({ queryKey: ['plots'] })
    },
  })
}

export function useDeletePlot() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (plotId: string) => plotService.deletePlot(plotId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plots'] })
    },
  })
}

// Facility queries
export function useFacilities() {
  return useQuery({
    queryKey: ['facilities'],
    queryFn: () => facilityService.getFacilities(),
  })
}

export function useFacility(facilityId: string) {
  return useQuery({
    queryKey: ['facility', facilityId],
    queryFn: () => facilityService.getFacility(facilityId),
    enabled: !!facilityId,
  })
}

export function useFacilityPlots(facilityId: string) {
  return useQuery({
    queryKey: ['facilityPlots', facilityId],
    queryFn: () => facilityService.getFacilityPlots(facilityId),
    enabled: !!facilityId,
  })
}

// Facility mutations
export function useCreateFacility() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: CreateFacilityRequest) => facilityService.createFacility(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['facilities'] })
    },
  })
}

// Plot thresholds query
export function usePlotThresholds(plotId: string) {
  return useQuery({
    queryKey: ['plotThresholds', plotId],
    queryFn: () => plotService.getPlotThresholds(plotId),
    enabled: !!plotId,
  })
}

// Plot thresholds mutation
export function useUpdatePlotThresholds() {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: ({ plotId, thresholds }: { plotId: string; thresholds: any }) =>
      plotService.updatePlotThresholds(plotId, thresholds),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['plotThresholds', variables.plotId] })
    },
  })
}

// Facility responsibles queries
export function useFacilityResponsibles(facilityId: string) {
  return useQuery({
    queryKey: ['facilityResponsibles', facilityId],
    queryFn: () => facilityService.getFacilityResponsibles(facilityId),
    enabled: !!facilityId,
  })
}

export function useUpdateFacilityResponsibles() {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: ({ facilityId, responsibles }: { facilityId: string; responsibles: string[] }) =>
      facilityService.updateFacilityResponsibles(facilityId, responsibles),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['facilityResponsibles', variables.facilityId] })
    },
  })
}

// Irrigation queries
export function useLastIrrigation(plotId: string) {
  return useQuery({
    queryKey: ['lastIrrigation', plotId],
    queryFn: () => irrigationService.getLastIrrigation(plotId),
    enabled: !!plotId,
    refetchInterval: 300000, // Refetch every 5 minutes
    retry: false, // Don't retry if no irrigation data exists
  })
}

export function useIrrigations(plotId: string) {
  return useQuery({
    queryKey: ['irrigations', plotId],
    queryFn: () => irrigationService.getIrrigations(plotId),
    enabled: !!plotId,
  })
}

export function useFacilityIrrigations(facilityId: string, date?: string) {
  return useQuery({
    queryKey: ['facilityIrrigations', facilityId, date],
    queryFn: () => irrigationService.getFacilityIrrigations(facilityId, date),
    enabled: !!facilityId,
  })
}

// Species queries
export function useSpecies() {
  return useQuery({
    queryKey: ['species'],
    queryFn: () => speciesService.getSpecies(),
  })
}

// Species mutations
export function useCreateSpecies() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: { name: string }) => speciesService.createSpecies(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['species'] })
    },
  })
}
