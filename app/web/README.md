# MERIDA Smart Grow - Frontend

Modern React + TypeScript frontend for the MERIDA Smart Grow IoT Platform.

## Tech Stack

- **Framework**: React 18 + TypeScript
- **Build Tool**: Vite
- **Styling**: Tailwind CSS
- **Routing**: React Router v6
- **State Management**: Zustand
- **Data Fetching**: Axios + React Query (TanStack Query)
- **Authentication**: AWS Cognito (via AWS Amplify)
- **Charts**: Recharts
- **Icons**: Heroicons
- **UI Components**: Headless UI

## Getting Started

### Prerequisites

- Node.js 20.19.0 or later
- npm or yarn

### Installation

1. Install dependencies:

```bash
npm install
```

2. Copy environment variables:

```bash
cp .env.example .env
```

3. Update the `.env` file with your configuration:

```env
VITE_API_BASE_URL=http://localhost:8000
VITE_AWS_REGION=us-east-1
VITE_COGNITO_USER_POOL_ID=your-user-pool-id
VITE_COGNITO_CLIENT_ID=your-client-id
```

### Development

Start the development server:

```bash
npm run dev
```

The application will be available at `http://localhost:3000`

### Building for Production

Build the application:

```bash
npm run build
```

Preview the production build:

```bash
npm run preview
```

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Fix ESLint errors
- `npm run format` - Format code with Prettier
- `npm run type-check` - Run TypeScript type checking

## Project Structure

```
src/
├── components/          # Reusable UI components
│   ├── common/         # Shared components (ProtectedRoute, etc.)
│   ├── dashboard/      # Dashboard-specific components
│   ├── plots/          # Plot management components
│   └── auth/           # Authentication components
├── pages/              # Page components
│   ├── Dashboard/      # Dashboard page
│   ├── Plots/          # Plots management page
│   └── Auth/           # Authentication pages
├── layouts/            # Layout components
│   ├── MainLayout.tsx  # Main app layout with sidebar
│   └── AuthLayout.tsx  # Authentication layout
├── hooks/              # Custom React hooks
│   ├── useAuth.tsx     # Authentication hook
│   └── useQueries.ts   # React Query hooks
├── services/           # API service functions
│   ├── api.ts          # Axios instance and interceptors
│   ├── plotService.ts  # Plot API endpoints
│   └── userService.ts  # User API endpoints
├── store/              # Zustand state stores
│   └── slices/         # Store slices
│       ├── userStore.ts
│       └── plotStore.ts
├── types/              # TypeScript type definitions
│   └── index.ts
├── config/             # App configuration
│   ├── auth.ts         # AWS Cognito configuration
│   └── api.ts          # API configuration
├── utils/              # Utility functions
├── App.tsx             # Root component
└── main.tsx            # Entry point
```

## Features

### Authentication
- AWS Cognito authentication
- Protected routes
- Automatic token refresh

### Dashboard
- Real-time sensor data display
- Temperature, humidity, soil moisture, and light readings
- Historical data visualization with charts
- Auto-refresh every 30 seconds

### Plot Management
- View all plots
- Create new plots
- Update plot information
- Delete plots
- Select plots for detailed view

### API Integration
- Centralized API client with Axios
- React Query for data fetching and caching
- Automatic retry and error handling
- Request/response interceptors

## AWS Amplify Deployment

The project includes an `amplify.yml` configuration file for AWS Amplify hosting.

### Deploy to Amplify

1. Connect your repository to AWS Amplify
2. Amplify will automatically detect the `amplify.yml` configuration
3. Set environment variables in Amplify Console:
   - `VITE_API_BASE_URL`
   - `VITE_AWS_REGION`
   - `VITE_COGNITO_USER_POOL_ID`
   - `VITE_COGNITO_CLIENT_ID`
4. Deploy!

## Code Quality

### ESLint

The project uses ESLint with TypeScript and React configurations.

```bash
npm run lint       # Check for issues
npm run lint:fix   # Fix issues automatically
```

### Prettier

Code formatting with Prettier and Tailwind CSS plugin.

```bash
npm run format
```

### TypeScript

Strict TypeScript configuration for type safety.

```bash
npm run type-check
```

## Environment Variables

All environment variables must be prefixed with `VITE_` to be accessible in the application.

Required variables:

- `VITE_API_BASE_URL` - Backend API URL
- `VITE_AWS_REGION` - AWS region
- `VITE_COGNITO_USER_POOL_ID` - Cognito User Pool ID
- `VITE_COGNITO_CLIENT_ID` - Cognito Client ID

Optional variables:

- `VITE_APP_NAME` - Application name
- `VITE_APP_VERSION` - Application version

## Backend Integration

The frontend expects the following API endpoints:

- `GET /users/:userId` - Get user profile
- `GET /users/:userId/plots` - Get user's plots
- `GET /plot/:plotId` - Get plot details
- `POST /plot` - Create new plot
- `PUT /plot/:plotId` - Update plot
- `DELETE /plot/:plotId` - Delete plot
- `GET /plot/:plotId/state` - Get current plot state
- `GET /plot/:plotId/history` - Get historical sensor data

## Contributing

1. Create a new branch for your feature
2. Make your changes
3. Run linting and type checking
4. Submit a pull request

## License

Private - MERIDA Smart Grow IoT Platform
