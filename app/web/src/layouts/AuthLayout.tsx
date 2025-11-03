import { Outlet } from 'react-router-dom'

export function AuthLayout() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-primary-50 to-primary-100 px-4 py-12 sm:px-6 lg:px-8">
      <div className="w-full max-w-md">
        <div className="text-center">
          <h1 className="mb-2 text-4xl font-bold text-primary-600">MERIDA Smart Grow</h1>
          <p className="mb-8 text-gray-600">IoT Platform for Smart Agriculture</p>
        </div>
        <div className="rounded-lg bg-white px-8 py-10 shadow-xl">
          <Outlet />
        </div>
      </div>
    </div>
  )
}
