import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { plotService } from '@/services/plotService'
import { userService } from '@/services/userService'
import { CreatePlotRequest, UpdatePlotRequest } from '@/types'

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
    refetchInterval: 30000, // Refetch every 30 seconds
  })
}

export function usePlotHistory(plotId: string, startDate?: string, endDate?: string) {
  return useQuery({
    queryKey: ['plotHistory', plotId, startDate, endDate],
    queryFn: () => plotService.getPlotHistory(plotId, startDate, endDate),
    enabled: !!plotId,
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
