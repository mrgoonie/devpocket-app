# DevPocket Project Overview

## Purpose
DevPocket is a mobile-first cloud IDE that turns smartphones into powerful development machines. It provides containerized development environments accessible through a mobile interface with terminal access, web preview, and environment management.

## Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider pattern
- **HTTP Client**: Dio with Retrofit
- **WebSocket**: web_socket_channel
- **Storage**: flutter_secure_storage (encrypted)
- **UI Library**: Custom Neobrutalism design system
- **Authentication**: JWT with Google Sign-In
- **Terminal**: xterm package
- **WebView**: webview_flutter
- **Code Generation**: build_runner, json_serializable, retrofit_generator

## Architecture
- **Models**: Data classes with JSON serialization
- **Services**: API, WebSocket, Auth, Storage services
- **Providers**: State management using ChangeNotifier
- **Screens**: Feature-based UI screens
- **Widgets**: Reusable UI components following Neobrutalism design
- **Utils**: Error handling and utility functions