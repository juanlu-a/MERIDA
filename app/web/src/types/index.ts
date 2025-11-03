// User types
export interface User {
  user_id: string
  email?: string
  name?: string
  created_at?: string
}

// Plot types
export interface PlotMetadata {
  plot_id: string
  facility_id: string
  species?: string
  area?: number
  created_at: string
  updated_at?: string
}

export interface PlotState {
  plot_id: string
  timestamp: string
  temperature?: number
  humidity?: number
  soil_moisture?: number
  light?: number
}

export interface CreatePlotRequest {
  facility_id: string
  species?: string
  area?: number
}

export interface UpdatePlotRequest {
  species?: string
  area?: number
}

// Sensor data types
export interface SensorData {
  sensor_id: string
  plot_id: string
  timestamp: string
  temperature?: number
  humidity?: number
  soil_moisture?: number
  light?: number
}

// Event types
export interface Event {
  event_type: string
  timestamp: string
  plot_id?: string
  data?: Record<string, unknown>
}

// Facility types
export interface Facility {
  facility_id: string
  name: string
  location?: string
  created_at: string
}

// API Response types
export interface ApiResponse<T> {
  data: T
  message?: string
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  page_size: number
}
