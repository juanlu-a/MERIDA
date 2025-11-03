import { usePlotState, usePlotHistory } from '@/hooks/useQueries'
import { usePlotStore } from '@/store/slices/plotStore'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts'
import { useEffect } from 'react'

export function DashboardPage() {
  const { selectedPlot } = usePlotStore()

  // For demo purposes, using a hardcoded plot ID
  // In production, this would come from user selection or URL params
  const plotId = selectedPlot?.plot_id || 'demo-plot-001'

  const { data: currentState, isLoading: stateLoading } = usePlotState(plotId)
  const { data: history, isLoading: historyLoading } = usePlotHistory(plotId)

  if (stateLoading) {
    return (
      <div className="flex h-96 items-center justify-center">
        <div className="h-16 w-16 animate-spin rounded-full border-b-2 border-t-2 border-primary-600"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-2 text-gray-600">Monitor your plots and sensor data in real-time</p>
      </div>

      {/* Current readings */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Temperature"
          value={currentState?.temperature?.toFixed(1) || '--'}
          unit="°C"
          color="bg-red-500"
        />
        <StatCard
          title="Humidity"
          value={currentState?.humidity?.toFixed(1) || '--'}
          unit="%"
          color="bg-blue-500"
        />
        <StatCard
          title="Soil Moisture"
          value={currentState?.soil_moisture?.toFixed(1) || '--'}
          unit="%"
          color="bg-green-500"
        />
        <StatCard
          title="Light"
          value={currentState?.light?.toFixed(0) || '--'}
          unit="lux"
          color="bg-yellow-500"
        />
      </div>

      {/* Historical data charts */}
      {!historyLoading && history && history.length > 0 && (
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <ChartCard title="Temperature & Humidity">
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={history}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  dataKey="timestamp"
                  tickFormatter={(value) => new Date(value).toLocaleTimeString()}
                />
                <YAxis />
                <Tooltip labelFormatter={(value) => new Date(value).toLocaleString()} />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="temperature"
                  stroke="#ef4444"
                  name="Temperature (°C)"
                />
                <Line type="monotone" dataKey="humidity" stroke="#3b82f6" name="Humidity (%)" />
              </LineChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title="Soil Moisture & Light">
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={history}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  dataKey="timestamp"
                  tickFormatter={(value) => new Date(value).toLocaleTimeString()}
                />
                <YAxis />
                <Tooltip labelFormatter={(value) => new Date(value).toLocaleString()} />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="soil_moisture"
                  stroke="#22c55e"
                  name="Soil Moisture (%)"
                />
                <Line type="monotone" dataKey="light" stroke="#eab308" name="Light (lux)" />
              </LineChart>
            </ResponsiveContainer>
          </ChartCard>
        </div>
      )}

      {historyLoading && (
        <div className="flex h-96 items-center justify-center">
          <p className="text-gray-500">Loading historical data...</p>
        </div>
      )}

      {!historyLoading && (!history || history.length === 0) && (
        <div className="rounded-lg bg-white p-8 text-center shadow">
          <p className="text-gray-500">No historical data available for this plot.</p>
        </div>
      )}
    </div>
  )
}

function StatCard({
  title,
  value,
  unit,
  color,
}: {
  title: string
  value: string
  unit: string
  color: string
}) {
  return (
    <div className="overflow-hidden rounded-lg bg-white shadow">
      <div className="p-6">
        <div className="flex items-center">
          <div className={`rounded-md ${color} p-3`}>
            <div className="h-6 w-6 text-white" />
          </div>
          <div className="ml-4 flex-1">
            <p className="text-sm font-medium text-gray-500">{title}</p>
            <p className="text-2xl font-semibold text-gray-900">
              {value} <span className="text-base text-gray-500">{unit}</span>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

function ChartCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-lg bg-white p-6 shadow">
      <h3 className="mb-4 text-lg font-semibold text-gray-900">{title}</h3>
      {children}
    </div>
  )
}
