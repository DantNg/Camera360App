# Camera360App

A comprehensive Flutter application for controlling and managing Ricoh Theta 360-degree cameras with Firebase authentication, live streaming, and panorama viewing capabilities.

## Project Overview

Camera360App is a mobile application built with Flutter that provides complete control over Ricoh Theta cameras. The application features user authentication via Firebase, camera control for capturing photos and videos, real-time streaming, and an interactive panorama viewer for 360-degree content.

## Key Features

### 1. Authentication System
- **Firebase Authentication**: Secure user authentication system
- User registration and login
- Password recovery functionality
- Persistent user sessions
- Secure logout mechanism

### 2. Camera Control
- **Theta Camera Integration**: Direct control of Ricoh Theta cameras
- **Photo Capture**: Take 360-degree panoramic photos
- **Video Recording**: Record 360-degree videos
- **Camera Settings**: Configure camera parameters (endpoint, authentication)
- **File Management**: Browse and manage captured media files
- Settings persistence using SharedPreferences

### 3. Live Streaming
- **Real-time Streaming**: Stream live feed from Theta cameras
- **Normal View Mode**: Standard streaming view
- **Panorama View Mode**: Interactive 360-degree streaming
- Configurable stream server settings
- Start/stop streaming controls

### 4. Media Library
- **Local Library Access**: Browse device gallery
- **Panorama Viewer**: Interactive 360-degree photo viewer
- Touch controls for panorama navigation
- Fullscreen viewing support

### 5. User Interface
- Modern dark theme with gradient design
- Intuitive navigation
- Responsive layouts
- Custom material design components

## Project Structure

### `/lib` - Main Application Code

#### `/auth` - Authentication Module
- `firebase_options.dart` - Firebase configuration and initialization
- `login_page.dart` - User login interface and logic
- `signup_page.dart` - User registration interface
- `forgot_password_page.dart` - Password recovery functionality
- `home_page.dart` - Main dashboard after authentication

#### `/camera` - Camera Control Module
- `my_camera.dart` - Main camera control interface
- `take_picture_screen.dart` - Photo capture functionality
- `capture_video_screen.dart` - Video recording interface
- `photo_screen.dart` - Photo preview and management
- `video_screen.dart` - Video playback interface
- `file_list_screen.dart` - Media file browser
- `settings_screen.dart` - Camera settings configuration
- `message_box.dart` - UI utility for displaying messages

##### `/camera/panorama`
- `panorama_photo_screen.dart` - Interactive 360-degree photo viewer with touch controls

##### `/camera/capture_library`
- `library_screen.dart` - Device gallery access for selecting panorama images

#### `/stream` - Live Streaming Module
- `stream_player_screen.dart` - Main streaming interface
- `camera_stream_service.dart` - Stream management service
- `normal_stream_viewer.dart` - Standard streaming view
- `panorama_stream_viewer.dart` - 360-degree streaming view
- `stream_setting.dart` - Stream configuration settings

#### `/theme` - UI Theming
- `constants.dart` - Application-wide theme constants and gradients

### `/packages/theta_client_flutter` - Theta Camera SDK
Custom Flutter plugin for Ricoh Theta camera integration

#### `/lib` - SDK Core
- `theta_client_flutter.dart` - Main SDK interface
- `digest_auth.dart` - HTTP digest authentication for camera API

##### `/capture`
- `capture.dart` - Photo/video capture implementations
- `capture_builder.dart` - Capture configuration builder
- `capturing.dart` - Capture state management

##### `/options`
- Camera configuration options (Bluetooth, Ethernet, file formats, etc.)
- `file_format.dart` - Media format configurations
- `max_recordable_time.dart` - Recording time limits
- `off_delay.dart` - Auto power-off settings
- `sleep_delay.dart` - Sleep mode configuration

##### `/state`
- `theta_state.dart` - Camera state monitoring
- `capture_status.dart` - Capture operation status
- `state_gps_info.dart` - GPS information from camera

##### `/utils`
- `convert_utils.dart` - Data conversion utilities

### `/android` - Android Platform Configuration
- Gradle build scripts
- Android manifest files
- Google Services configuration for Firebase

### `/assets` - Application Resources
- `background_theta_z1.jpg` - Application background image

## Dependencies

### Core Dependencies
- `flutter` - Flutter framework
- `firebase_core: ^3.4.0` - Firebase core functionality
- `firebase_auth: ^5.2.0` - Firebase authentication
- `theta_client_flutter` - Custom Theta camera SDK (local package)

### Media & Streaming
- `video_player: ^2.9.1` - Video playback
- `panorama_viewer: ^1.0.5` - 360-degree panorama viewer
- `image_picker: ^1.1.2` - Gallery and camera access
- `video_360: ^0.0.9` - 360-degree video support
- `vr_player: ^0.2.2` - VR video player
- `webview_flutter: ^4.9.0` - Web view integration

### Networking & Storage
- `http: ^1.2.2` - HTTP client
- `http_auth: ^1.0.4` - HTTP authentication
- `crypto: ^3.0.5` - Cryptographic functions
- `shared_preferences: ^2.3.2` - Local data persistence
- `path_provider: ^2.1.4` - File system path access

### UI Components
- `cupertino_icons: ^1.0.8` - iOS style icons

## Setup Instructions

### Prerequisites
1. Flutter SDK (3.5.1 or higher)
2. Android Studio or VS Code with Flutter extensions
3. Firebase project with Authentication enabled
4. Ricoh Theta camera (for full functionality)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Camera360App
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Download `google-services.json` and place it in `/android/app/`
   - Update Firebase configuration in `lib/auth/firebase_options.dart`

4. **Run the application**
   ```bash
   flutter run
   ```

## Configuration

### Camera Setup
1. Launch the app and log in
2. Navigate to Camera Control
3. Configure camera settings:
   - **Endpoint**: Camera IP address (e.g., `http://192.168.1.1`)
   - **Username**: Camera authentication username (if required)
   - **Password**: Camera authentication password (if required)

### Stream Server Setup
1. Navigate to Stream Player
2. Enter stream server URL (e.g., `http://192.168.0.110:8080`)
3. Configure camera IP address for streaming

## Usage

### Taking Photos
1. Open Camera Control from home screen
2. Ensure camera is connected
3. Tap "Take Picture"
4. View captured photos in file list

### Recording Videos
1. Open Camera Control
2. Tap "Capture Video"
3. Start/stop recording
4. Access recordings from file list

### Viewing Panoramas
1. Option 1: Open Local Library and select image from gallery
2. Option 2: Capture photo and view from file list
3. Use two fingers to rotate and explore 360-degree view

### Live Streaming
1. Configure stream server in Stream Player
2. Select view mode (Normal or Panorama)
3. Start streaming
4. View live feed from camera

## Technical Details

### Architecture
- **MVVM Pattern**: Separation of UI and business logic
- **Firebase Integration**: Cloud-based authentication
- **Local Storage**: SharedPreferences for settings persistence
- **Custom Plugin**: Theta client as local Flutter package

### Platform Support
- Android (primary target)
- iOS (with additional configuration)

### Authentication Flow
1. User opens app → Login screen
2. Login/Register → Firebase authentication
3. Success → Home page with navigation options
4. Logout → Return to login screen

### Camera Communication
- HTTP/HTTPS protocol
- Digest authentication support
- REST API for camera control
- WebSocket for live streaming

## Development

### Building for Production
```bash
flutter build apk --release  # Android APK
flutter build appbundle     # Android App Bundle
flutter build ios           # iOS build
```

### Testing
```bash
flutter test
```

## Troubleshooting

### Camera Connection Issues
- Verify camera is powered on and Wi-Fi is enabled
- Check endpoint URL format and IP address
- Ensure device is connected to camera's Wi-Fi network

### Streaming Issues
- Verify stream server is running
- Check server URL and port configuration
- Ensure network connectivity between camera and server

### Firebase Authentication Issues
- Verify `google-services.json` is properly configured
- Check Firebase Authentication is enabled in console
- Ensure internet connection is available

## Future Enhancements
- Cloud storage integration for media files
- Social sharing features
- Advanced camera controls (ISO, exposure, etc.)
- Multi-camera support
- Offline mode capabilities
- Enhanced video editing features

## Resources

### Flutter Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Flutter Samples](https://flutter.github.io/samples/)

### Ricoh Theta Resources
- [Theta API Documentation](https://api.ricoh/docs/theta-web-api/)
- [Theta Developer Guide](https://developers.theta360.com/)

### Firebase Resources
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

## Support
For issues and feature requests, please contact the development team.
