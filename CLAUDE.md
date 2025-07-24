# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

This is a Flutter project. Use these commands for development:

- **Run the app**: `flutter run`
- **Run tests**: `flutter test`
- **Build for production**: `flutter build apk` (Android) or `flutter build ios` (iOS)
- **Get dependencies**: `flutter pub get`
- **Clean project**: `flutter clean`
- **Analyze code**: `flutter analyze`
- **Format code**: `dart format .`

## Project Architecture

### App Structure
- **Main entry point**: `lib/main.dart` - Sets up Firebase, providers (ThemeProvider, AuthProvider), and HTTP overrides
- **Routing**: Uses `BottomTabRouter` with PageView for tab-based navigation between 4 main screens
- **State management**: Provider pattern with ChangeNotifier providers for theme and authentication state
- **Authentication**: Firebase Auth with Google Sign-In and Sign in with Apple support

### Key Features
- **Health integration**: Uses `health` package to integrate with Apple Health/Google Fit
- **Articles system**: WebView-based article reading with categories
- **Theme support**: Light/dark mode toggle with persistent storage using FlutterSecureStorage
- **Cross-platform**: Supports iOS, Android, macOS, Linux, Windows, and Web

### Directory Structure
- `lib/src/constants/` - App-wide constants (colors, fonts, theme)
- `lib/src/features/` - Feature-specific modules (articles, health, profile, settings)
- `lib/src/screens/` - Main screen widgets
- `lib/src/routing/` - Navigation logic
- `lib/src/utils/` - Utility functions and helpers
- `lib/src/widgets/` - Reusable UI components

### Dependencies
- **UI/UX**: flutter_svg, fl_chart, cupertino_icons
- **HTTP**: http package for API calls
- **Storage**: flutter_secure_storage for sensitive data
- **Authentication**: firebase_auth, google_sign_in, sign_in_with_apple
- **Health**: health package for fitness data integration
- **State**: provider for state management
- **Web**: webview_flutter for article viewing

### Firebase Configuration
- Firebase is initialized in main.dart with platform-specific options
- Authentication providers are configured for Google and Apple sign-in
- Uses FirebaseAuth.instance.authStateChanges() for auth state listening

### Theme System
- Supports light/dark themes with Material 3 design
- Theme preference persisted in secure storage
- Asset paths change based on theme (dark/light logo variants)
- Uses custom color schemes defined in src/constants/theme.dart

### Platform-Specific Considerations
- Android: Custom padding for app bar to handle status bar
- iOS: Uses standard app bar height
- Health permissions required for health data access
- Proper entitlements configured for iOS/macOS builds