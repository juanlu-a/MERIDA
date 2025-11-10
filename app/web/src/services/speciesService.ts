import { apiClient } from './api'

export interface Species {
  pk: string
  sk: string
  name: string
  type: string
}

export interface SpeciesListResponse {
  count: number
  species: Species[]
}

export interface CreateSpeciesRequest {
  name: string
}

export const speciesService = {
  getSpecies: async (): Promise<Species[]> => {
    const response = await apiClient.get<SpeciesListResponse>('/species/')
    return response.data.species || []
  },

  createSpecies: async (data: CreateSpeciesRequest): Promise<Species> => {
    const response = await apiClient.post('/species/', data)
    return response.data.created_species
  },
}

