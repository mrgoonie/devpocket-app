# Onboarding Flow Implementation Tasks

## Overview
Implement a smooth onboarding experience for new users including registration, email verification, and profile setup.

## Tasks

### 1. Registration Screen ✅
- [x] Create registration screen with email/password fields
- [x] Add form validation (email format, password strength)
- [x] Integrate with `/api/v1/auth/register` endpoint
- [x] Handle registration errors (duplicate email, validation)
- [x] Navigate to email verification after successful registration

### 2. Email Verification Screen ✅
- [x] Create verification screen with code input
- [x] Show user's email and instructions
- [x] Integrate with `/api/v1/auth/verify-email` endpoint
- [x] Add resend verification email functionality
- [x] Handle verification success/failure
- [x] Auto-navigate to home after verification

### 3. Google OAuth Integration ✅
- [x] Add Google Sign-In button to login/register screens
- [x] Configure Google OAuth credentials
- [x] Integrate with `/api/v1/auth/google` endpoint
- [x] Handle OAuth flow and tokens
- [x] Skip email verification for Google users

### 4. Onboarding Flow Manager ✅
- [x] Create onboarding state management
- [x] Track user progress through onboarding
- [x] Handle navigation between onboarding steps
- [x] Persist onboarding state
- [x] Skip completed steps on app restart

## API Endpoints

### Register
- POST `/api/v1/auth/register`
- Body: `{ username, email, password, full_name? }`
- Response: `{ user: UserResponse }`

### Verify Email
- POST `/api/v1/auth/verify-email`
- Body: `{ token }`
- Response: `{ message, user }`

### Resend Verification
- POST `/api/v1/auth/resend-verification`
- Headers: `Authorization: Bearer <token>`
- Response: `{ message }`

### Google OAuth
- POST `/api/v1/auth/google`
- Body: `{ id_token }`
- Response: `{ access_token, token_type, user }`

## UI/UX Requirements

### Registration Screen
- Clean form with email, username, password fields
- Password strength indicator
- Show/hide password toggle
- Terms of service checkbox
- Loading state during registration
- Error messages below fields

### Email Verification
- Large, clear instruction text
- 6-digit code input field
- Resend button with cooldown timer
- Success animation
- Auto-focus on code input

### Google OAuth
- Prominent Google Sign-In button
- Loading state during OAuth flow
- Error handling for cancelled/failed auth

## Technical Implementation

### State Management
- Use AuthProvider for authentication state
- Create OnboardingProvider for flow management
- Store verification email temporarily
- Handle token storage after verification

### Navigation
- Linear flow: Register → Verify → Home
- Skip verification for Google users
- Deep link support for email verification
- Back button handling

### Security
- Validate email format client-side
- Enforce password requirements
- Secure token storage
- Clear sensitive data on logout

## Testing Checklist
- [ ] Test registration with valid/invalid data
- [ ] Test email verification flow
- [ ] Test resend verification functionality
- [ ] Test Google OAuth flow
- [ ] Test navigation between steps
- [ ] Test error handling
- [ ] Test deep linking
- [ ] Test state persistence