import { useState } from 'react'
import { usePlots, useCreatePlot, useDeletePlot } from '@/hooks/useQueries'
import { usePlotStore } from '@/store/slices/plotStore'
import { PlusIcon, TrashIcon } from '@heroicons/react/24/outline'
import { CreatePlotRequest } from '@/types'

export function PlotsPage() {
  const [showCreateModal, setShowCreateModal] = useState(false)

  // For demo purposes, using a hardcoded user ID
  // In production, this would come from the auth context
  const userId = 'demo-user-001'

  const { data: plots, isLoading } = usePlots(userId)
  const createPlot = useCreatePlot()
  const deletePlot = useDeletePlot()
  const { setSelectedPlot } = usePlotStore()

  const handleDelete = async (plotId: string) => {
    if (confirm('Are you sure you want to delete this plot?')) {
      await deletePlot.mutateAsync(plotId)
    }
  }

  if (isLoading) {
    return (
      <div className="flex h-96 items-center justify-center">
        <div className="h-16 w-16 animate-spin rounded-full border-b-2 border-t-2 border-primary-600"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Plots</h1>
          <p className="mt-2 text-gray-600">Manage your agricultural plots and facilities</p>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="inline-flex items-center rounded-md bg-primary-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-primary-700"
        >
          <PlusIcon className="mr-2 h-5 w-5" />
          Add Plot
        </button>
      </div>

      {plots && plots.length > 0 ? (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {plots.map((plot) => (
            <div key={plot.plot_id} className="overflow-hidden rounded-lg bg-white shadow">
              <div className="p-6">
                <h3 className="text-lg font-semibold text-gray-900">Plot {plot.plot_id}</h3>
                <dl className="mt-4 space-y-2 text-sm">
                  <div>
                    <dt className="inline font-medium text-gray-500">Facility: </dt>
                    <dd className="inline text-gray-900">{plot.facility_id}</dd>
                  </div>
                  {plot.species && (
                    <div>
                      <dt className="inline font-medium text-gray-500">Species: </dt>
                      <dd className="inline text-gray-900">{plot.species}</dd>
                    </div>
                  )}
                  {plot.area && (
                    <div>
                      <dt className="inline font-medium text-gray-500">Area: </dt>
                      <dd className="inline text-gray-900">{plot.area} m²</dd>
                    </div>
                  )}
                  <div>
                    <dt className="inline font-medium text-gray-500">Created: </dt>
                    <dd className="inline text-gray-900">
                      {new Date(plot.created_at).toLocaleDateString()}
                    </dd>
                  </div>
                </dl>
                <div className="mt-4 flex space-x-2">
                  <button
                    onClick={() => setSelectedPlot(plot)}
                    className="flex-1 rounded-md bg-primary-50 px-3 py-2 text-sm font-medium text-primary-600 hover:bg-primary-100"
                  >
                    View Details
                  </button>
                  <button
                    onClick={() => handleDelete(plot.plot_id)}
                    className="rounded-md bg-red-50 p-2 text-red-600 hover:bg-red-100"
                  >
                    <TrashIcon className="h-5 w-5" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="rounded-lg bg-white p-12 text-center shadow">
          <p className="text-gray-500">No plots found. Create your first plot to get started!</p>
          <button
            onClick={() => setShowCreateModal(true)}
            className="mt-4 inline-flex items-center rounded-md bg-primary-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-primary-700"
          >
            <PlusIcon className="mr-2 h-5 w-5" />
            Create Plot
          </button>
        </div>
      )}

      {showCreateModal && (
        <CreatePlotModal
          onClose={() => setShowCreateModal(false)}
          onCreate={async (data) => {
            await createPlot.mutateAsync(data)
            setShowCreateModal(false)
          }}
        />
      )}
    </div>
  )
}

function CreatePlotModal({
  onClose,
  onCreate,
}: {
  onClose: () => void
  onCreate: (data: CreatePlotRequest) => void
}) {
  const [facilityId, setFacilityId] = useState('')
  const [species, setSpecies] = useState('')
  const [area, setArea] = useState('')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onCreate({
      facility_id: facilityId,
      species: species || undefined,
      area: area ? parseFloat(area) : undefined,
    })
  }

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-screen items-center justify-center px-4">
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75" onClick={onClose}></div>
        <div className="relative w-full max-w-md rounded-lg bg-white p-6 shadow-xl">
          <h3 className="mb-4 text-lg font-semibold text-gray-900">Create New Plot</h3>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Facility ID <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                required
                value={facilityId}
                onChange={(e) => setFacilityId(e.target.value)}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-primary-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Species</label>
              <input
                type="text"
                value={species}
                onChange={(e) => setSpecies(e.target.value)}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-primary-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Area (m²)</label>
              <input
                type="number"
                step="0.01"
                value={area}
                onChange={(e) => setArea(e.target.value)}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-primary-500"
              />
            </div>
            <div className="flex space-x-2">
              <button
                type="button"
                onClick={onClose}
                className="flex-1 rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="flex-1 rounded-md bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700"
              >
                Create
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
