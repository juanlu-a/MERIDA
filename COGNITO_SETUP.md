# Cognito User Management Guide

## 🔐 AWS Cognito Configuration

**User Pool ID**: `us-east-1_FYMYK5jN1`  
**Client ID**: `11plns2dpqj8gpsqirg1plocke`  
**Region**: `us-east-1`

---

## 📝 Creating Users

### Option 1: AWS CLI (Recommended for Development)

#### Create User with Temporary Password

```bash
aws cognito-idp admin-create-user \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username testuser@example.com \
  --user-attributes \
    Name=email,Value=testuser@example.com \
    Name=name,Value="Test User" \
  --temporary-password "TempPass123!" \
  --message-action SUPPRESS \
  --region us-east-1
```

#### Set Permanent Password

```bash
aws cognito-idp admin-set-user-password \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username testuser@example.com \
  --password "SecurePassword123!" \
  --permanent \
  --region us-east-1
```

#### Create User with Permanent Password (Single Command)

```bash
# Create user
aws cognito-idp admin-create-user \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username admin@merida.com \
  --user-attributes \
    Name=email,Value=admin@merida.com \
    Name=name,Value="Admin User" \
    Name=email_verified,Value=true \
  --message-action SUPPRESS \
  --region us-east-1

# Set permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username admin@merida.com \
  --password "Admin123!Secure" \
  --permanent \
  --region us-east-1
```

---

### Option 2: AWS Console

1. Go to [AWS Cognito Console](https://console.aws.amazon.com/cognito/)
2. Click on **User Pools** → Select `us-east-1_FYMYK5jN1`
3. Go to **Users** tab
4. Click **Create user**
5. Fill in:
   - **Username**: `testuser@example.com`
   - **Email**: `testuser@example.com`
   - **Temporary password**: Generate or specify
   - Uncheck "Send invitation email"
6. Click **Create user**
7. Select the user and click **Actions** → **Confirm user** (to verify email)
8. Click **Actions** → **Set password** to set a permanent password

---

## 👥 Sample Users for Testing

### Create Multiple Test Users

```bash
#!/bin/bash
# create-test-users.sh

USER_POOL_ID="us-east-1_FYMYK5jN1"
REGION="us-east-1"

# Admin User
echo "Creating admin user..."
aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username admin@merida.com \
  --user-attributes Name=email,Value=admin@merida.com Name=name,Value="Admin User" Name=email_verified,Value=true \
  --message-action SUPPRESS \
  --region $REGION

aws cognito-idp admin-set-user-password \
  --user-pool-id $USER_POOL_ID \
  --username admin@merida.com \
  --password "Admin123!" \
  --permanent \
  --region $REGION

# Regular User 1
echo "Creating user1..."
aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username user1@merida.com \
  --user-attributes Name=email,Value=user1@merida.com Name=name,Value="User One" Name=email_verified,Value=true \
  --message-action SUPPRESS \
  --region $REGION

aws cognito-idp admin-set-user-password \
  --user-pool-id $USER_POOL_ID \
  --username user1@merida.com \
  --password "User123!" \
  --permanent \
  --region $REGION

# Regular User 2
echo "Creating user2..."
aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username user2@merida.com \
  --user-attributes Name=email,Value=user2@merida.com Name=name,Value="User Two" Name=email_verified,Value=true \
  --message-action SUPPRESS \
  --region $REGION

aws cognito-idp admin-set-user-password \
  --user-pool-id $USER_POOL_ID \
  --username user2@merida.com \
  --password "User123!" \
  --permanent \
  --region $REGION

echo "✅ All test users created successfully!"
```

**Save as** `scripts/create-cognito-users.sh` and run:
```bash
chmod +x scripts/create-cognito-users.sh
./scripts/create-cognito-users.sh
```

---

## 🔍 User Management Commands

### List All Users

```bash
aws cognito-idp list-users \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --region us-east-1
```

### Get User Details

```bash
aws cognito-idp admin-get-user \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username testuser@example.com \
  --region us-east-1
```

### Delete User

```bash
aws cognito-idp admin-delete-user \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username testuser@example.com \
  --region us-east-1
```

### Enable User

```bash
aws cognito-idp admin-enable-user \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username testuser@example.com \
  --region us-east-1
```

### Disable User

```bash
aws cognito-idp admin-disable-user \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username testuser@example.com \
  --region us-east-1
```

### Reset Password

```bash
aws cognito-idp admin-reset-user-password \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username testuser@example.com \
  --region us-east-1
```

---

## 🧪 Testing Authentication

### Test Login with AWS CLI

```bash
aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id 11plns2dpqj8gpsqirg1plocke \
  --auth-parameters \
    USERNAME=testuser@example.com,PASSWORD=SecurePassword123! \
  --region us-east-1
```

**Expected Response**:
```json
{
  "ChallengeParameters": {},
  "AuthenticationResult": {
    "AccessToken": "eyJraWQiOi...",
    "ExpiresIn": 3600,
    "TokenType": "Bearer",
    "RefreshToken": "eyJjdHkiOi...",
    "IdToken": "eyJraWQiOi..."
  }
}
```

### Test with Frontend Application

1. Start the frontend:
   ```bash
   cd app/web
   npm run dev
   ```

2. Open http://localhost:5173

3. Click **Login**

4. Enter credentials:
   - **Email**: `testuser@example.com`
   - **Password**: `SecurePassword123!`

5. Should redirect to dashboard on successful login

---

## 🔐 Password Requirements

- **Minimum length**: 8 characters
- **Must contain**: 
  - At least 1 uppercase letter (A-Z)
  - At least 1 lowercase letter (a-z)
  - At least 1 number (0-9)
  - At least 1 special character (!@#$%^&*)

**Valid password examples**:
- `SecurePass123!`
- `MyPassword2024@`
- `Admin#2025Strong`

---

## 🛠️ Troubleshooting

### User Not Confirmed

If you see "User is not confirmed" error:

```bash
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username testuser@example.com \
  --region us-east-1
```

### Email Not Verified

```bash
aws cognito-idp admin-update-user-attributes \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username testuser@example.com \
  --user-attributes Name=email_verified,Value=true \
  --region us-east-1
```

### Check User Status

```bash
aws cognito-idp admin-get-user \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username testuser@example.com \
  --region us-east-1 \
  --query 'UserStatus'
```

**User Status Values**:
- `FORCE_CHANGE_PASSWORD`: User needs to change temporary password
- `CONFIRMED`: User is active and verified
- `UNCONFIRMED`: User created but not confirmed
- `ARCHIVED`: User is disabled
- `COMPROMISED`: User account is compromised
- `UNKNOWN`: Unknown status

---

## 📱 Frontend Integration

The frontend is already configured to use Cognito. The authentication flow is handled by AWS Amplify:

**Configuration Location**: `app/web/src/config/auth.ts`

```typescript
import { Amplify } from 'aws-amplify'

const authConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'us-east-1_FYMYK5jN1',
      userPoolClientId: '11plns2dpqj8gpsqirg1plocke',
      region: 'us-east-1',
    },
  },
}

Amplify.configure(authConfig)
```

---

## 🔗 Useful Links

- [AWS Cognito Console](https://us-east-1.console.aws.amazon.com/cognito/v2/idp/user-pools/us-east-1_FYMYK5jN1/users)
- [AWS CLI Cognito Commands](https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/)
- [AWS Amplify Auth Documentation](https://docs.amplify.aws/lib/auth/getting-started/q/platform/js/)
