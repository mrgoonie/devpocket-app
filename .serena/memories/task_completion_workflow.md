# Task Completion Workflow

## After Completing Tasks

### Code Quality Checks
1. **Run Analysis**: `flutter analyze` - Fix any linting issues
2. **Format Code**: `dart format .` - Ensure consistent formatting
3. **Test Code**: `flutter test` - Verify functionality

### Code Generation
- If models or services were modified: `flutter pub run build_runner build --delete-conflicting-outputs`

### Testing
- Unit tests for services and providers
- Widget tests for UI components
- Manual testing on target devices

### Commit Guidelines
- Use conventional commit format
- Keep commits focused on actual changes
- **NEVER** add AI attribution signatures
- Professional, clean commit messages

### Before Production
- Verify API endpoints configuration
- Ensure proper error handling
- Check authentication flows
- Test WebSocket connections
- Validate UI responsiveness