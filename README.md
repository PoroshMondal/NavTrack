# NavTrack — Route & Car Navigation

A production-grade, single-screen Flutter application for Android built according to Senior Mobile Developer Technical Assessment standards. 

**NavTrack** fetches real-time native location, renders OpenStreetMap tiles, retrieves driving routes using the public OSRM API, and animates a car marker smoothly along the decoded polyline geometry with live distance/ETA metrics and camera follow capabilities.

---

## Features

- **Native Android Location**: Implemented directly in Kotlin using `FusedLocationProviderClient` without third-party location plugins (`geolocator`, `location`, `permission_handler`).
- **OpenStreetMap & flutter_map**: Renders crisp OpenStreetMap tiles with attribution and package user-agent configuration.
- **Long-Press Destination Selection**: Deliberate destination selection on map long-press.
- **OSRM Polyline Route Fetching**: Retrieves driving geometry from public OSRM server, decodes Precision 5 polylines, and fits map camera to route bounds.
- **Stale Route Request Protection**: Sequence-based request ID guarding prevents out-of-order network responses from overwriting newer selections.
- **Distance-Based Constant Speed Animation Engine**: Smooth car movement using cumulative Haversine distance, immune to uneven point spacing.
- **Bearing Calculation & Shortest Rotation**: Calculates directional heading and handles $359^\circ \to 1^\circ$ boundary transitions without backward spinning.
- **Navigation Controls**: Start, Pause, Resume, Reset controls and speed multipliers (`1x`, `2x`, `5x`).
- **Live Distance & ETA**: Real-time remaining distance and estimated time calculation updating as the car progresses.
- **Camera Auto-Follow & Manual Pan Recenter**: Camera tracks car during navigation; stops auto-follow when user manually pans map and displays a floating **Recenter** button.
- **Android Flavors (`dev` & `prod`)**: Configured via Gradle productFlavors with unique application IDs (`com.navtrack.nav_track.dev` vs `com.navtrack.nav_track`), different launcher names, and a floating **DEV** badge banner in dev mode.

---

## Architecture & Folder Structure

Built using **Clean Architecture** with strict **Unidirectional Data Flow**:

```
lib/
├── main.dart                       # Default fallback entrypoint
├── main_dev.dart                   # Dev flavor entrypoint
├── main_prod.dart                  # Prod flavor entrypoint
│
├── core/
│   ├── config/                     # AppConfig & FlavorType
│   ├── error/                      # Typed Exceptions & Failures
│   ├── network/                    # HTTP client configuration
│   └── utils/                      # Bearing, GeoMath & PolylineDecoder
│
├── domain/
│   ├── entities/                   # Coordinate, Location, Route, NavStep
│   ├── repositories/               # Location & Route repository contracts
│   └── usecases/                   # Pure Dart use cases (InterpolateRoute, FetchRoute, etc.)
│
├── data/
│   ├── datasources/                # Native Method/EventChannel & OSRM REST API
│   ├── models/                     # LocationModel & OsrmRouteResponse
│   └── repositories/               # Repository implementations
│
├── presentation/
│   ├── common/                     # DevBadgeBanner, Themes
│   ├── location/                   # LocationCubit & LocationState
│   ├── map/                        # MapCubit, CustomMapView, CarMarkerWidget, RecenterButton
│   ├── route/                      # RouteBloc, RouteEvent, RouteState
│   └── navigation/                 # NavigationCubit, NavTrackPage, NavigationControls
│
└── injection/
    └── dependency_injection.dart  # GetIt service locator setup
```

---

## Native Location Architecture (Flutter ↔ Kotlin)

1. **MethodChannel (`com.navtrack/location_method`)**:
   - `getCurrentLocation`: One-shot high-accuracy location via `FusedLocationProviderClient`.
   - `checkPermission` & `requestPermission`: Native runtime permission handling (`ACCESS_FINE_LOCATION`).
   - `openAppSettings`: Launches native Android Application Settings screen for permanently denied permissions.
2. **EventChannel (`com.navtrack/location_event`)**:
   - `locationStream`: Registers continuous `LocationCallback` with interval `2000ms` and fastest interval `1000ms`.
   - Automatically unregisters updates on `onCancel()` to ensure zero native background leaks.

---

## Route Animation & Geometry Approach

- **Constant-Speed Traversal**: Calculates segment distance $d = V_{\text{base}} \times \text{multiplier} \times \Delta t$ and interpolates across cumulative Haversine distances.
- **Shortest Angle Delta**: Rotates heading angle using $\Delta \theta = (\theta_{\text{target}} - \theta_{\text{current}} + 540^\circ) \bmod 360^\circ - 180^\circ$.
- **Robust Math Safeguard**: Handles repeated or zero-distance polyline coordinates without generating `NaN` or `Infinity`.

---

## Requirements & Environment

- **Flutter SDK**: `^3.12.2` (Dart `^3.5.0`)
- **Android SDK**: `minSdk = 21`, `compileSdk = 34`
- **Key Dependencies**:
  - `flutter_bloc: ^8.1.3`
  - `get_it: ^7.6.0`
  - `flutter_map: ^6.1.0`
  - `latlong2: ^0.9.1`
  - `http: ^1.2.0`
  - `dartz: ^0.10.1`

---

## How to Run

### Install Dependencies
```bash
flutter pub get
```

### Run Dev Flavor
```bash
flutter run -t lib/main_dev.dart --flavor dev
```

### Run Prod Flavor
```bash
flutter run -t lib/main_prod.dart --flavor prod
```

### Run Unit Tests
```bash
flutter test
```

### Build Release APKs
```bash
# Build Dev APK
flutter build apk -t lib/main_dev.dart --flavor dev --release

# Build Prod APK
flutter build apk -t lib/main_prod.dart --flavor prod --release
```

---

## Decisions & Documentation
For detailed architectural rationale, mathematical formulas, and trade-offs, refer to [DECISIONS.md](DECISIONS.md).
