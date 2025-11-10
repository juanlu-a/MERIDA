import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'

export function LoginPage() {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [newName, setNewName] = useState('')
  const [newGivenName, setNewGivenName] = useState('')
  const [newFamilyName, setNewFamilyName] = useState('')
  const [needsNewPassword, setNeedsNewPassword] = useState(false)
  const [requiredAttributes, setRequiredAttributes] = useState<string[]>([])
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { login } = useAuth()
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    if (needsNewPassword) {
      if (!newPassword || !confirmPassword) {
        setError('Please enter and confirm your new password.')
        return
      }
      if (newPassword !== confirmPassword) {
        setError('New password and confirmation do not match.')
        return
      }

      if (requiredAttributes.includes('name') && !newName) {
        setError('Please provide your name.')
        return
      }
    }

    setLoading(true)

    try {
      const attributePayload: Record<string, string> = {}
      if (needsNewPassword && requiredAttributes.includes('name')) {
        attributePayload.name = newName || username
      }
      if (needsNewPassword && requiredAttributes.includes('given_name')) {
        attributePayload.given_name = newGivenName || newName || username
      }
      if (needsNewPassword && requiredAttributes.includes('family_name')) {
        attributePayload.family_name = newFamilyName || newName || username
      }
      if (needsNewPassword && requiredAttributes.includes('email') && username.includes('@')) {
        attributePayload.email = username
      }
      console.debug('[Auth] login attribute payload:', attributePayload)

      const result = await login(
        username,
        password,
        needsNewPassword ? newPassword : undefined,
        needsNewPassword ? attributePayload : undefined,
      )

      if (result.requiresNewPassword) {
        console.debug('[Auth] new password required, attributes:', result.requiredAttributes)
        setNeedsNewPassword(true)
        setRequiredAttributes(result.requiredAttributes ?? [])
        if ((result.requiredAttributes ?? []).includes('name') && !newName) {
          setNewName(username)
        }
        if ((result.requiredAttributes ?? []).includes('given_name') && !newGivenName) {
          setNewGivenName(newName || username)
        }
        if ((result.requiredAttributes ?? []).includes('family_name') && !newFamilyName) {
          setNewFamilyName(newName || username)
        }
        setError('You must set a new password before continuing.')
        return
      }

      navigate('/dashboard')
    } catch (err: unknown) {
      const errorMessage =
        err instanceof Error ? err.message : 'Failed to login. Please check your credentials.'
      setError(errorMessage)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <h2 className="mb-6 text-center text-2xl font-bold text-gray-900">Sign in to your account</h2>

      {error && <div className="mb-4 rounded-md bg-red-50 p-4 text-sm text-red-800">{error}</div>}

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label htmlFor="username" className="block text-sm font-medium text-gray-700">
            Username or Email
          </label>
          <input
            id="username"
            type="text"
            required
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            className="focus:border-primary-500 focus:ring-primary-500 mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:outline-none"
            disabled={loading}
          />
        </div>

        <div>
          <label htmlFor="password" className="block text-sm font-medium text-gray-700">
            Password
          </label>
          <input
            id="password"
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="focus:border-primary-500 focus:ring-primary-500 mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:outline-none"
            disabled={loading}
          />
        </div>

        {needsNewPassword && (
          <>
            <div>
              <label htmlFor="new-password" className="block text-sm font-medium text-gray-700">
                New Password
              </label>
              <input
                id="new-password"
                type="password"
                required
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                className="focus:border-primary-500 focus:ring-primary-500 mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:outline-none"
                disabled={loading}
              />
            </div>

            {requiredAttributes.includes('name') && (
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                  Full Name
                </label>
                <input
                  id="name"
                  type="text"
                  required
                  value={newName || username}
                  onChange={(e) => setNewName(e.target.value)}
                  className="focus:border-primary-500 focus:ring-primary-500 mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:outline-none"
                  disabled={loading}
                />
              </div>
            )}

            {requiredAttributes.includes('given_name') && (
              <div>
                <label htmlFor="given-name" className="block text-sm font-medium text-gray-700">
                  Given Name
                </label>
                <input
                  id="given-name"
                  type="text"
                  required
                  value={newGivenName || newName || username}
                  onChange={(e) => setNewGivenName(e.target.value)}
                  className="focus:border-primary-500 focus:ring-primary-500 mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:outline-none"
                  disabled={loading}
                />
              </div>
            )}

            {requiredAttributes.includes('family_name') && (
              <div>
                <label htmlFor="family-name" className="block text-sm font-medium text-gray-700">
                  Family Name
                </label>
                <input
                  id="family-name"
                  type="text"
                  required
                  value={newFamilyName || newName || username}
                  onChange={(e) => setNewFamilyName(e.target.value)}
                  className="focus:border-primary-500 focus:ring-primary-500 mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:outline-none"
                  disabled={loading}
                />
              </div>
            )}

            <div>
              <label htmlFor="confirm-password" className="block text-sm font-medium text-gray-700">
                Confirm New Password
              </label>
              <input
                id="confirm-password"
                type="password"
                required
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className="focus:border-primary-500 focus:ring-primary-500 mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:outline-none"
                disabled={loading}
              />
            </div>
          </>
        )}

        <div>
          <button
            type="submit"
            disabled={loading}
            className="hover:bg-primary-700 focus:ring-primary-500 flex w-full justify-center rounded-md bg-amber-600 px-4 py-2 text-sm font-medium text-white shadow-sm focus:ring-2 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:bg-gray-400"
          >
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </div>
      </form>
    </div>
  )
}
