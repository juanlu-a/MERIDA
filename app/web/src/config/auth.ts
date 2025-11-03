import { Amplify } from 'aws-amplify'

const authConfig = {
  Auth: {
    Cognito: {
      userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID || '',
      userPoolClientId: import.meta.env.VITE_COGNITO_CLIENT_ID || '',
      region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
    },
  },
}

// Configure Amplify
Amplify.configure(authConfig)

export default authConfig
