# 📱 DevPocket - Mobile-First Cloud IDE

**Code anywhere, anytime.** DevPocket is the world's first mobile-native cloud IDE that turns your phone into a powerful development machine.

## ✨ Features

### 🎯 Core Features
- **Mobile-First Design**: Built from the ground up for touch interfaces
- **Cloud Environments**: Instant access to containerized development environments
- **Full Terminal Access**: Real-time terminal with WebSocket connection
- **WebView Browser**: Preview your applications with developer tools
- **Multi-Language Support**: Python, Node.js, Go, Rust, and more

### 🔐 Authentication
- **JWT Authentication**: Secure token-based authentication
- **Google Sign-In**: Quick signup with Google account
- **Secure Storage**: Encrypted credential storage

### 🎨 Design
- **Dark Mode Only**: Optimized for mobile coding
- **Neobrutalism UI**: Bold, accessible design system
- **Brutalist Components**: Custom UI components with strong visual hierarchy

### ⚡ Performance
- **Real-time Updates**: Live environment status and metrics
- **Auto-reconnect**: Robust WebSocket connection management
- **Offline Capability**: Local storage for critical data

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.0.0 or higher)
- **Dart SDK** (3.0.0 or higher)
- **Android Studio** or **Xcode** (for mobile development)
- **Git**

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/devpocket-app.git
   cd devpocket-app
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate required files**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Add required assets**
   
   Create the following directory structure and add assets:
   ```
   assets/
   ├── fonts/
   │   ├── JetBrainsMono-Regular.ttf
   │   ├── JetBrainsMono-Bold.ttf
   │   ├── Inter-Regular.ttf
   │   ├── Inter-Bold.ttf
   │   └── Inter-SemiBold.ttf
   ├── images/
   └── icons/
       └── google.png
   ```

5. **Configure API endpoints**
   
   Update the API configuration in `lib/config/constants.dart`:
   ```dart
   static const String apiBaseUrl = 'https://your-api-server.com';
   static const String wsBaseUrl = 'wss://your-websocket-server.com';
   ```

   Production API endponts:
   ```dart
   static const String apiBaseUrl = 'https://devpocket-api.goon.vn';
   static const String wsBaseUrl = 'wss://devpocket-api.goon.vn';
   ```

   API Docs:
   - Swagger:  https://devpocket-api.goon.vn/docs
   - Redoc:    https://devpocket-api.goon.vn/redoc

6. **Configure Google Sign-In**
   
   **For Android:**
   - Add your `google-services.json` file to `android/app/`
   - Update `android/app/build.gradle` with your signing configuration
   
   **For iOS:**
   - Add your `GoogleService-Info.plist` file to `ios/Runner/`
   - Update `ios/Runner/Info.plist` with URL schemes

### Running the App

1. **Start your development server** (backend API)

2. **Run the Flutter app**
   ```bash
   # For development
   flutter run
   
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   ```

3. **Build for production**
   ```bash
   # Android APK
   flutter build apk --release
   
   # Android App Bundle
   flutter build appbundle --release
   
   # iOS
   flutter build ios --release
   ```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   ├── constants.dart        # App constants and configuration
│   └── theme.dart           # Neobrutalism theme configuration
├── models/
│   ├── user.dart            # User data models
│   ├── environment.dart     # Environment data models
│   ├── auth_response.dart   # Authentication response models
│   └── error_response.dart  # Error response models
├── services/
│   ├── auth_service.dart    # Authentication API service
│   ├── api_service.dart     # General API service
│   ├── websocket_service.dart # WebSocket connection service
│   └── storage_service.dart # Secure local storage
├── providers/
│   ├── auth_provider.dart   # Authentication state management
│   └── environment_provider.dart # Environment state management
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── loading/
│   │   └── loading_screen.dart
│   ├── main/
│   │   └── main_screen.dart
│   ├── terminal/
│   │   └── terminal_screen.dart
│   ├── webview/
│   │   └── webview_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── widgets/
│   ├── brutalist_button.dart      # Custom button component
│   ├── brutalist_text_field.dart  # Custom text field component
│   └── environment_selector.dart  # Environment selection widget
└── utils/
    └── error_handler.dart    # Comprehensive error handling
```

## 🎨 Design System

DevPocket uses a **Neobrutalism** design system with the following principles:

### Color Palette
- **Primary Black**: `#000000`
- **Primary White**: `#FFFFFF`
- **Neon Green**: `#00FF41` (Primary accent)
- **Neon Pink**: `#FF006B` (Secondary accent)
- **Neon Blue**: `#0070F3` (Info accent)
- **Neon Yellow**: `#FFD700` (Warning)
- **Dark Background**: `#0A0A0A`
- **Dark Surface**: `#1A1A1A`
- **Dark Card**: `#2A2A2A`

### Typography
- **Primary Font**: Inter (UI text)
- **Monospace Font**: JetBrains Mono (Terminal and code)

### Components
- **High Contrast**: Strong borders and shadows
- **Bold Shapes**: Rounded rectangles with thick borders
- **Shadow Effects**: Consistent 4px offset shadows
- **Bright Accents**: Neon colors for interactive elements

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# API Configuration
API_BASE_URL=https://your-api-server.com
WS_BASE_URL=wss://your-websocket-server.com

# Google Sign-In
GOOGLE_CLIENT_ID=your-google-client-id

# App Configuration
APP_NAME=DevPocket
APP_VERSION=1.0.0
```

### Backend Requirements

DevPocket requires a backend server that provides:

1. **Authentication API**
   - POST `/api/v1/auth/login`
   - POST `/api/v1/auth/register`
   - POST `/api/v1/auth/google`
   - POST `/api/v1/auth/refresh`
   - GET `/api/v1/auth/me`
   - POST `/api/v1/auth/logout`
   - POST `/api/v1/auth/verify-email`

2. **Environment Management API**
   - GET `/api/v1/environments`
   - POST `/api/v1/environments`
   - GET `/api/v1/environments/{id}`
   - PUT `/api/v1/environments/{id}`
   - DELETE `/api/v1/environments/{id}`
   - POST `/api/v1/environments/{id}/start`
   - POST `/api/v1/environments/{id}/stop`
   - POST `/api/v1/environments/{id}/restart`
   - GET `/api/v1/environments/{id}/metrics`
   - GET `/api/v1/environments/{id}/logs`

3. **WebSocket Terminal API**
   - WS `/api/v1/ws/terminal/{environmentId}`

4. **Cluster Management API**
   - GET `/api/v1/clusters`
   - POST `/api/v1/clusters`
   - GET `/api/v1/clusters/{id}`
   - PUT `/api/v1/clusters/{id}`
   - DELETE `/api/v1/clusters/{id}`

5. **Template Management API**
   - GET `/api/v1/templates`
   - POST `/api/v1/templates`
   - GET `/api/v1/templates/{id}`
   - PUT `/api/v1/templates/{id}`
   - DELETE `/api/v1/templates/{id}`

See `docs/FLUTTER_INTEGRATION.md` for complete API documentation.

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Test Structure

```
test/
├── unit/
│   ├── services/
│   ├── providers/
│   └── models/
├── widget/
│   ├── screens/
│   └── widgets/
└── integration/
    └── app_test.dart
```

## 📱 Platform-Specific Setup

### Android Setup

1. **Minimum SDK**: Android 21 (Android 5.0)
2. **Target SDK**: Android 34
3. **Permissions**: Internet, network state
4. **ProGuard**: Configured for release builds

### iOS Setup

1. **Minimum Version**: iOS 12.0
2. **Permissions**: Network access
3. **App Transport Security**: Configured for HTTPS

## 🔒 Security Best Practices

### Authentication
- JWT tokens stored in encrypted secure storage
- Automatic token refresh
- Google Sign-In integration
- Session timeout handling

### API Security
- HTTPS-only communication
- Request/response validation
- Error message sanitization
- Rate limiting support

### Data Protection
- Sensitive data encryption
- Secure local storage
- No credentials in source code
- Proper error logging without exposing secrets

## 🚀 Deployment

### Android Deployment

1. **Generate signing key**
   ```bash
   keytool -genkey -v -keystore ~/devpocket-release-key.keystore -name devpocket -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **Configure gradle**
   Update `android/app/build.gradle` with signing configuration

3. **Build release**
   ```bash
   flutter build appbundle --release
   ```

### iOS Deployment

1. **Configure Xcode project**
   - Set bundle identifier
   - Configure signing certificates
   - Set deployment target

2. **Build for App Store**
   ```bash
   flutter build ios --release
   ```

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for your changes
5. Ensure all tests pass (`flutter test`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Code Style

- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for code formatting
- Run `flutter analyze` for static analysis
- Write tests for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Acknowledgments

- **Flutter Team** - For the amazing cross-platform framework
- **xterm** - For terminal emulation
- **dio** - For HTTP client functionality
- **provider** - For state management
- **Community** - For feedback and contributions

## 📞 Support

- **Email**: support@devpocket.io
- **Discord**: [Join our Discord](https://discord.gg/devpocket)
- **Documentation**: [docs.devpocket.io](https://docs.devpocket.io)
- **Issues**: [GitHub Issues](https://github.com/yourusername/devpocket-app/issues)

---

**Built with ❤️ by the DevPocket team**

*Code anywhere, anytime. 📱*