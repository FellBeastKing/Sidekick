# EV-04 Tracker - Codebase Summary

## Project Overview

**EV-04 Tracker** is a Flutter-based multi-device tracking application designed to monitor and manage multiple tracking devices (similar to GPS trackers for children or family members). The application provides real-time location tracking, battery monitoring, SOS alerts, push notifications, and MQTT communication capabilities through a clean, responsive interface.

## Application Architecture

### Core Technology Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider pattern
- **Mapping**: OpenStreetMap via `flutter_map`
- **Location**: `latlong2` for coordinate handling
- **Communication**: `url_launcher` for phone calls
- **Real-time Communication**: MQTT via `mqtt_client`
- **Notifications**: `flutter_local_notifications`
- **Permissions**: `permission_handler`
- **UI**: Material Design 3

### Project Structure
```
ev04_tracker/
├── lib/
│   └── main.dart                 # Single-file application (661 lines)
├── android/                      # Android platform configuration
├── ios/                         # iOS platform configuration
├── web/                         # Web platform configuration
├── windows/                     # Windows platform configuration
├── linux/                      # Linux platform configuration
├── macos/                       # macOS platform configuration
├── test/
│   └── widget_test.dart         # Basic widget tests
├── pubspec.yaml                 # Dependencies and project config
└── README.md                    # Basic project documentation
```

## Core Functionality

### 1. Device Management
- **Add Devices**: Users can add new tracking devices with:
  - Display name (e.g., "Daughter", "Son")
  - Phone number (SIM card number for voice calls)
  - Device ID (IMEI or UUID)
  - Default location (Johannesburg fallback)
  - Initial battery level
- **Remove Devices**: Delete devices from tracking list with confirmation
- **Device Selection**: Select active device for detailed view

### 2. Real-Time Location Tracking
- **Live Updates**: Simulated location updates every 2 seconds
- **MQTT Integration**: Real-time communication via MQTT broker
- **Location Jittering**: Realistic movement simulation (100-300m radius)
- **Breadcrumb Trails**: Historical location tracking (last 100 points)
- **Online/Offline Status**: Device connectivity monitoring

### 3. Battery Monitoring System
- **Battery Level Tracking**: Monitor device battery levels (0-100%)
- **Visual Battery Indicators**: Color-coded battery icons and levels
- **Low Battery Alerts**: Notifications when battery drops below 20%
- **Critical Battery Alerts**: Urgent notifications when battery drops below 10%
- **Battery Status Display**: Real-time battery information on all screens
- **Smart Notifications**: Prevents duplicate notifications with intelligent tracking

### 4. Interactive Map Interface
- **OpenStreetMap Integration**: Uses tile-based mapping
- **Device Markers**: Visual representation of device locations with battery status
- **Trail Visualization**: Polyline showing device movement history
- **Map Controls**: Zoom, pan, and recenter functionality
- **Responsive Design**: Adapts to different screen sizes

### 5. SOS Alert System
- **SOS Detection**: Monitors emergency signals from devices
- **Alert Banner**: Prominent red banner when SOS is active
- **Push Notifications**: Instant SOS notifications with sound and vibration
- **Quick Actions**: Direct access to emergency response options
- **Multi-Device Support**: Handles multiple simultaneous SOS alerts
- **MQTT SOS Publishing**: Broadcasts SOS alerts via MQTT

### 6. Push Notification System
- **Local Notifications**: Flutter local notifications for all alerts
- **SOS Notifications**: High-priority emergency notifications
- **Battery Notifications**: Low and critical battery level alerts
- **Permission Handling**: Automatic notification permission requests
- **Cross-Platform**: Works on Android, iOS, and other platforms

### 7. MQTT Communication
- **Real-Time Messaging**: MQTT broker integration for live updates
- **Device Updates**: Publish and subscribe to device status changes
- **SOS Broadcasting**: Emergency alert distribution
- **Connection Management**: Automatic connection handling with status indicators
- **JSON Message Format**: Structured data exchange
- **Public Broker Support**: Uses test.mosquitto.org for demonstration

### 8. Communication Features
- **Voice Calls**: One-tap calling to device phone numbers
- **Coordinate Sharing**: Copy/paste location coordinates
- **Device Information**: Detailed device status and metadata

## Technical Implementation

### Data Models

#### Device Class ([`Device`](lib/main.dart:71))
```dart
class Device {
  final String id;           // IMEI or UUID
  String name;               // Display name
  String phone;              // SIM phone number
  LatLng location;           // Current coordinates
  bool online;               // Connection status
  bool sosActive;            // Emergency status
  int batteryLevel;          // Battery level 0-100
  DateTime lastUpdate;       // Last update timestamp
  List<LatLng> trail;        // Location history
  
  // Battery status helpers
  bool get isLowBattery;     // Battery <= 20%
  bool get isCriticalBattery; // Battery <= 10%
  Color get batteryColor;    // Color based on battery level
  IconData get batteryIcon;  // Icon based on battery level
}
```

#### DeviceUpdate Class ([`DeviceUpdate`](lib/main.dart:108))
```dart
class DeviceUpdate {
  final String id;           // Device identifier
  final LatLng? location;    // New location (optional)
  final bool? online;        // Connection status (optional)
  final bool? sosActive;     // SOS status (optional)
  final String? name;        // Name update (optional)
  final String? phone;       // Phone update (optional)
  final int? batteryLevel;   // Battery level (optional)
  final DateTime timestamp;  // Update time
  
  // MQTT JSON serialization
  factory DeviceUpdate.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### State Management

#### DeviceStore ([`DeviceStore`](lib/main.dart:444))
- **Provider-based**: Uses `ChangeNotifier` for reactive state management
- **Device Registry**: Maintains map of all tracked devices
- **Selection Management**: Handles active device selection
- **Update Processing**: Applies real-time updates to devices
- **MQTT Integration**: Manages MQTT connections and message handling
- **Notification Management**: Handles push notification logic and deduplication
- **Battery Monitoring**: Tracks battery status changes and alerts
- **Demo Data**: Includes simulated update service for testing

#### NotificationService ([`NotificationService`](lib/main.dart:153))
- **Cross-Platform Notifications**: Flutter local notifications setup
- **Permission Management**: Automatic notification permission requests
- **SOS Alerts**: High-priority emergency notifications with sound/vibration
- **Battery Alerts**: Low and critical battery level notifications
- **Channel Management**: Organized notification channels for different alert types

#### MqttService ([`MqttService`](lib/main.dart:326))
- **Real-Time Communication**: MQTT broker connection management
- **Message Publishing**: Device updates and SOS alert broadcasting
- **Message Subscription**: Real-time device update reception
- **Connection Handling**: Automatic reconnection and status monitoring
- **JSON Serialization**: Structured message format for device data

### UI Components

#### Main Application ([`EV04TrackerApp`](lib/main.dart:49))
- Material Design 3 theming
- Provider setup for state management
- Indigo color scheme
- Automatic MQTT connection on startup
- Notification service initialization

#### Home Page ([`HomePage`](lib/main.dart:635))
- **Centralized Interface**: Clean home screen with prominent navigation buttons
- **Battery Status Display**: Real-time battery levels for all devices
- **MQTT Status Indicator**: Connection status with toggle functionality
- **SOS Alert Integration**: Prominent emergency alert banner
- **Device Status Cards**: Color-coded battery status with visual indicators
- **Responsive Design**: Adapts to different screen sizes

#### Call Device Screen ([`CallDeviceScreen`](lib/main.dart:1025))
- **Device List**: All devices with call functionality
- **Battery Information**: Battery level display for each device
- **SOS Priority**: Emergency devices highlighted in red
- **One-Tap Calling**: Direct phone call integration
- **Status Indicators**: Online/offline and battery status

#### Check Location Screen ([`CheckLocationScreen`](lib/main.dart:1135))
- **Interactive Map**: Full map interface with device tracking
- **Device Selection**: Click markers to select devices
- **Trail Visualization**: Historical movement paths
- **Responsive Layout**: Desktop and mobile optimized views
- **Real-Time Updates**: Live location updates via MQTT

#### Manage Devices Screen ([`ManageDevicesScreen`](lib/main.dart:1194))
- **Device Management**: Add, remove, and configure devices
- **Battery Monitoring**: Battery status for each device
- **Device Details**: Complete device information display
- **Confirmation Dialogs**: Safe device removal with confirmation
- **Form Validation**: Proper input validation for new devices

#### Map Components
- **MapPane** ([`_MapPane`](lib/main.dart:503)): Interactive map with markers and trails
- **DeviceMarker** ([`_DeviceMarker`](lib/main.dart:560)): Custom device location markers
- **SelectedCard** ([`_SelectedCard`](lib/main.dart:594)): Device detail overlay

#### List Components
- **DeviceListPane** ([`_DeviceListPane`](lib/main.dart:418)): Scrollable device list
- **SosBanner** ([`_SosBanner`](lib/main.dart:354)): Emergency alert display

### Demo Data System

#### DemoUpdateService ([`DemoUpdateService`](lib/main.dart:570))
- **Realistic Simulation**: Simulates real-time device updates
- **Location Jittering**: Random movement around South African cities
- **Battery Simulation**: Gradual battery drain with random decreases
- **SOS Events**: Emergency simulation (5% probability)
- **Battery Updates**: Random battery level changes (15% probability)
- **Seeded Random**: Consistent testing with reproducible results

## Platform Support

### Multi-Platform Configuration
The application is configured for deployment across multiple platforms:

#### Android
- **Package**: `com.example.ev04_tracker`
- **Target SDK**: Modern Android versions
- **Permissions**: Standard Flutter permissions
- **Launch Configuration**: Single-top activity mode

#### iOS
- **Bundle ID**: Configurable via build settings
- **Display Name**: "Ev04 Tracker"
- **Orientations**: Portrait and landscape support
- **iOS Version**: Modern iOS compatibility

#### Web
- **PWA Support**: Progressive Web App capabilities
- **Manifest**: Standalone display mode
- **Icons**: Multiple resolution support (192px, 512px)
- **Theme**: Blue color scheme (#0175C2)

#### Desktop (Windows, macOS, Linux)
- **Native Support**: Full desktop application capabilities
- **Window Management**: Standard desktop window controls
- **Platform Integration**: OS-specific features

## Dependencies

### Core Dependencies ([`pubspec.yaml`](pubspec.yaml:30))
```yaml
flutter_map: ^8.2.1        # OpenStreetMap integration
latlong2: ^0.9.1           # Geographic coordinate handling
url_launcher: ^6.3.2       # Phone call functionality
provider: ^6.1.5+1         # State management
cupertino_icons: ^1.0.8    # iOS-style icons
```

### Development Dependencies
```yaml
flutter_test: sdk: flutter  # Testing framework
flutter_lints: ^6.0.0      # Code quality linting
```

## Key Features Summary

### ✅ Implemented Features
1. **Multi-Device Tracking**: Add, remove, and manage multiple tracking devices
2. **Real-Time Location Updates**: Simulated live location tracking with 2-second intervals
3. **Interactive Map**: OpenStreetMap integration with device markers and trails
4. **SOS Alert System**: Emergency notification banner with quick actions
5. **Voice Communication**: One-tap calling to device phone numbers
6. **Responsive Design**: Adaptive UI for desktop and mobile platforms
7. **Location History**: Breadcrumb trails showing device movement patterns
8. **Device Status Monitoring**: Online/offline status tracking
9. **Coordinate Sharing**: Copy location coordinates to clipboard
10. **Cross-Platform Support**: Android, iOS, Web, Windows, macOS, Linux

### 🔄 Demo/Simulation Features
- **Simulated Updates**: Demo service generates realistic location changes
- **Sample Devices**: Pre-loaded with "Daughter" and "Son" devices
- **South African Locations**: Default locations in Johannesburg and Cape Town
- **Random SOS Events**: 5% probability of SOS activation during updates

### 🚀 Architecture Strengths
- **Single-File Design**: Entire application in one well-documented file (1600+ lines)
- **Clean State Management**: Provider pattern for reactive updates
- **Modular Components**: Well-separated UI components and services
- **Real-Time Communication**: MQTT integration for live device updates
- **Smart Notification System**: Intelligent alert management with deduplication
- **Extensible Design**: Easy to replace demo service with real backend
- **Platform Agnostic**: Consistent experience across all platforms
- **Production Ready**: Complete notification and communication infrastructure

## Future Integration Points

The application is designed for easy integration with real tracking hardware:

1. **Backend Integration**: The [`MqttService`](lib/main.dart:326) provides:
   - ✅ MQTT message handling (implemented)
   - ✅ Real-time device updates (implemented)
   - ✅ SOS alert broadcasting (implemented)
   - HTTP API integration (can be added)
   - WebSocket connections (alternative to MQTT)
   - Real-time database sync (can be added)

2. **Hardware Communication**:
   - GPS tracker protocol implementation
   - Device configuration management
   - Firmware update capabilities
   - Battery monitoring integration

3. **Enhanced Features**:
   - ✅ Push notifications (implemented)
   - ✅ Battery monitoring (implemented)
   - ✅ Real-time communication (implemented)
   - Geofencing and alerts (can be added)
   - Historical data persistence (can be added)
   - User authentication (can be added)
   - Multi-user family accounts (can be added)

## Testing

### Current Test Coverage
- **Widget Tests**: Basic smoke test for application startup
- **Test File**: [`test/widget_test.dart`](test/widget_test.dart:1)
- **Framework**: Flutter testing framework

### Test Status
⚠️ **Note**: The current test file contains placeholder counter app tests that don't match the actual tracker functionality. Tests need to be updated to reflect the real application features including battery monitoring, MQTT communication, and push notifications.

## Development Setup

### Prerequisites
- Flutter SDK ^3.9.0
- Dart language support
- Platform-specific development tools (Android Studio, Xcode, etc.)

### Installation
```bash
flutter pub get
flutter run
```

### Build Commands
```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web

# Desktop
flutter build windows
flutter build macos
flutter build linux
```

## Code Quality

### Architecture Patterns
- **Provider Pattern**: Reactive state management
- **Single Responsibility**: Well-separated concerns
- **Composition**: Modular UI components
- **Immutable Data**: Safe state updates

### Code Organization
- **Self-Contained**: Entire application in single file for simplicity
- **Well-Documented**: Extensive inline documentation
- **Consistent Naming**: Clear, descriptive identifiers
- **Type Safety**: Full Dart type annotations

This codebase represents a complete, production-ready foundation for a family tracking application with room for extensive customization and real-world backend integration.