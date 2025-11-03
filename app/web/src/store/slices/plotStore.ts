import { create } from 'zustand'
import { PlotMetadata } from '@/types'

interface PlotState {
  plots: PlotMetadata[]
  selectedPlot: PlotMetadata | null
  setPlots: (plots: PlotMetadata[]) => void
  setSelectedPlot: (plot: PlotMetadata | null) => void
  addPlot: (plot: PlotMetadata) => void
  updatePlot: (plotId: string, updates: Partial<PlotMetadata>) => void
  removePlot: (plotId: string) => void
}

export const usePlotStore = create<PlotState>((set) => ({
  plots: [],
  selectedPlot: null,
  setPlots: (plots) => set({ plots }),
  setSelectedPlot: (plot) => set({ selectedPlot: plot }),
  addPlot: (plot) => set((state) => ({ plots: [...state.plots, plot] })),
  updatePlot: (plotId, updates) =>
    set((state) => ({
      plots: state.plots.map((p) => (p.plot_id === plotId ? { ...p, ...updates } : p)),
    })),
  removePlot: (plotId) => set((state) => ({ plots: state.plots.filter((p) => p.plot_id !== plotId) })),
}))
