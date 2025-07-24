# Code Style & Conventions

## Flutter/Dart Conventions
- **File Naming**: snake_case for files and directories
- **Class Naming**: PascalCase for classes
- **Variable Naming**: camelCase for variables and methods
- **Constants**: camelCase for const variables, ALL_CAPS for static const
- **Private Members**: Prefix with underscore (_)

## Project Patterns
- **State Management**: Provider pattern with ChangeNotifier
- **Models**: Immutable classes with Equatable, JSON serialization
- **Services**: Singleton classes for API, storage, WebSocket
- **Error Handling**: Comprehensive try-catch with user-friendly messages
- **Navigation**: Named routes, context-based navigation

## Code Generation
- Use `@JsonSerializable()` for model classes
- Use `@RestApi()` for service classes
- Run build_runner after changes to generated files

## UI Patterns
- **Theme**: Neobrutalism design with dark colors and neon accents
- **Colors**: Use AppTheme constants
- **Typography**: Inter for UI, JetBrains Mono for terminal/code
- **Components**: Brutalist buttons, text fields with bold borders