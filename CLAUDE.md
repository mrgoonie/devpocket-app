# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Running
- **Install dependencies**: `flutter pub get`
- **Generate code**: `flutter pub run build_runner build --delete-conflicting-outputs`
- **Run app**: `flutter run`
- **Run for specific platform**: `flutter run -d android` or `flutter run -d ios`
- **Build for production**: `flutter build apk --release` or `flutter build ios --release`

### Code Quality
- **Lint code**: `flutter analyze`
- **Format code**: `dart format .`
- **Run tests**: `flutter test`
- **Test with coverage**: `flutter test --coverage`

### Code Generation
When modifying models with `@JsonSerializable` annotations or services with `@RestApi` annotations, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Architecture Overview

### Project Structure
```
lib/
├── main.dart                 # App entry point with MultiProvider setup
├── config/
│   ├── constants.dart        # API endpoints and app configuration
│   └── theme.dart           # Neobrutalism theme implementation
├── models/                   # Data models with json_serializable
├── services/                 # API, WebSocket, Storage, and Auth services
├── providers/                # State management with Provider pattern
├── screens/                  # UI screens organized by feature
├── widgets/                  # Reusable UI components
└── utils/                    # Utility functions and helpers
```

### State Management
- Uses **Provider** pattern for state management
- Key providers: `AuthProvider`, `EnvironmentProvider`
- All providers extend `ChangeNotifier` and use `notifyListeners()` for updates
- Providers handle loading states, error states, and async operations

### Service Layer
- **ApiService**: REST API calls using Retrofit/Dio
- **WebSocketService**: Real-time terminal connections with reconnection logic
- **StorageService**: Secure storage for tokens and user data using `flutter_secure_storage`
- **AuthService**: Authentication flow including Google Sign-In and JWT handling

### Authentication Flow
- JWT-based authentication with automatic token refresh
- Tokens stored securely using `flutter_secure_storage`
- Auth interceptor automatically adds Bearer tokens to API requests
- Automatic logout on token refresh failure

### WebSocket Integration
- Terminal connections use WebSocket with `/api/v1/ws/terminal/{environmentId}` endpoint
- Implements exponential backoff reconnection strategy
- Handles connection status (connecting, connected, disconnected, error)
- Stream-based architecture for real-time terminal output

## Design System - Neobrutalism UI

### Colors
- **Primary**: Black `#000000`, White `#FFFFFF`
- **Accents**: Neon Green `#00FF41`, Neon Pink `#FF006B`, Neon Blue `#0070F3`, Neon Yellow `#FFD700`
- **Background**: Dark theme with `#0A0A0A`, `#1A1A1A`, `#2A2A2A` surfaces

### Typography
- **UI Text**: Inter font family
- **Terminal/Code**: JetBrains Mono
- Font weights: Regular (400), SemiBold (600), Bold (700)

### Component Patterns
- Bold borders (2-3px) with sharp corners
- Offset shadows for 3D depth effect
- High contrast color combinations
- Animated press states with scale transformations

## API Integration

### Base URLs
- Development: `http://localhost:8000` (API), `ws://localhost:8000` (WebSocket)
- Production: Update `constants.dart` with production URLs

### Key Endpoints
- Auth: `/api/v1/auth/{login,register,refresh,profile}`
- Environments: `/api/v1/environments` (CRUD operations)
- WebSocket: `/api/v1/ws/terminal/{environmentId}`

### Error Handling
- All services implement comprehensive error handling
- Auth errors (401) trigger automatic token refresh
- Network errors are user-friendly with retry mechanisms
- Error states are managed in providers with `_setError()` methods

## Development Workflow

### Adding New Features
1. Create models in `models/` with `@JsonSerializable` if needed
2. Add service methods in appropriate service class
3. Extend providers with new state management logic
4. Create UI components following Neobrutalism design patterns
5. Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
6. Test functionality and run `flutter analyze`

### Modifying UI Components
- Follow existing Neobrutalism patterns in `widgets/`
- Use theme colors from `theme.dart`
- Implement proper loading states and error handling
- Add animations using `flutter_animate` for state transitions

### Testing
- Unit tests for services and providers
- Widget tests for UI components
- Integration tests for complete user flows
- Mock external dependencies using `mockito`

## Important Notes

### Security
- Never commit API keys or sensitive credentials
- All sensitive data must use `flutter_secure_storage`
- Validate all user inputs and sanitize data
- Use HTTPS endpoints in production

### Terminal Integration
- Terminal uses `xterm` package for UI rendering
- WebSocket connection handles all terminal I/O
- Terminal state is managed in `TerminalScreen`
- Support for terminal resizing and command history

### Google Sign-In Setup
- Android: Add `google-services.json` to `android/app/`
- iOS: Add `GoogleService-Info.plist` to `ios/Runner/`
- Configure URL schemes in platform-specific files

## Common Issues

### Code Generation Errors
If build_runner fails, try:
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### WebSocket Connection Issues
- Check network connectivity and API endpoint configuration
- Verify authentication token validity
- Review connection status stream for debugging

### Authentication Problems
- Clear app data/storage if tokens are corrupted
- Verify Google Sign-In configuration files are present
- Check token expiry and refresh logic in `AuthProvider`

## Development rules

- always create/update `./plans/<FEATURE_NAME>_TASKS.md` to manage todos in every feature implementation/progress, update status of this file after finish each task
- ask questions for clarification of uncleared requests
- implement error catch handler and validation carefully
- follow security best practices
- focus on human-readable & developer-friendly when writing code
- high standard of user experience
- commit the code after every task implemented
- Keep commits focused on the actual code changes
- NEVER automatically add AI attribution signatures like:
  "🤖 Generated with [Claude Code]"
  "Co-Authored-By: Claude noreply@anthropic.com"
  Any AI tool attribution or signature
- Create clean, professional commit messages without AI references. Use conventional commit format.
- use `context7` MCP tool for documentation during implementation