# Architecture & Design Decisions — NavTrack

This document details the architectural, engineering, and mathematical rationale behind the **NavTrack — Route & Car Navigation** application.

---

## 1. Clean Architecture Choice
Clean Architecture was chosen to decouple core business logic (route calculation, distance interpolation, bearing rotation, and permission flows) from framework-dependent details such as UI widgets, map rendering packages (`flutter_map`), HTTP clients, and native Android platform channels. 

By enforcing strict dependency inversion:
* **Domain Layer**: Remains pure Dart and zero-dependency, enabling headless unit testing of navigation animation and bearing calculations without mounting Flutter widgets.
* **Data Layer**: Encapsulates external communications (`MethodChannel`, `EventChannel`, OSRM REST API) and maps raw payloads into domain entities.
* **Presentation Layer**: BLoCs/Cubits react exclusively to immutable domain entities and emit UI states.

---

## 2. State Management with BLoC & Cubit (`flutter_bloc`)
The application divides state management according to complexity and event dynamics:
* **`LocationCubit`**: Manages permission request flows, one-shot location fetching, and continuous location updates. Cubit was chosen here as state transitions are linear and status-driven.
* **`RouteBloc`**: Manages destination selection and OSRM route network calls. Bloc was chosen due to event-driven user actions (long-press map triggers `SelectDestinationEvent`) and the need for sequential request tracking.
* **`NavigationCubit`**: Drives the animation ticker for car movement along polyline geometry, speed multipliers (`1x`, `2x`, `5x`), and pause/resume states.
* **`MapCubit`**: Tracks camera auto-follow vs. user manual panning and controls recenter triggers.

Separating these concerns prevents massive singletons or bloated controllers, keeping UI updates surgical and efficient.

---

## 3. Platform Channels: MethodChannel vs EventChannel
* **MethodChannel (`com.navtrack/location_method`)**: Used for one-shot, request-response RPC calls (`getCurrentLocation`, `checkPermission`, `requestPermission`, `openAppSettings`, `isLocationServiceEnabled`). It is ideal for imperative actions with a single async return value.
* **EventChannel (`com.navtrack/location_event`)**: Used for continuous native location updates. When subscribed on the Flutter side, native Kotlin registers a `LocationCallback` with `FusedLocationProviderClient`. When cancelled or disposed, native Kotlin immediately calls `removeLocationUpdates()` to guarantee zero stream or listener leaks.

---

## 4. Native Error Mapping to Typed Failures
Native Android platform exceptions (`PERMISSION_DENIED`, `LOCATION_DISABLED`, `LOCATION_TIMEOUT`, `LOCATION_UNAVAILABLE`) are mapped on the data layer into typed Dart Exceptions, which are then converted by repositories into functional `Either<LocationFailure, T>` types. 

The UI receives structured domain failures instead of parsing arbitrary raw strings, allowing localized error messages, automatic dialog popups (e.g., "Open Settings"), and user-friendly banners.

---

## 5. Stale OSRM Request Protection
When a user rapidly long-presses multiple destinations on the map, async network responses may complete out-of-order. 

To prevent an older network request from overwriting a newer selection:
1. `RouteBloc` maintains an auto-incrementing `_requestIdCounter`.
2. Each `SelectDestinationEvent` generates a unique `requestId`.
3. `RouteRepositoryImpl` verifies `requestId >= _latestRequestId` both before making the HTTP call and upon receiving the response.
4. If a newer request was dispatched while an old HTTP request was in-flight, the old response is discarded with `StaleRouteRequestFailure`.

---

## 6. Navigation Engine & Geometry Mathematics

### A. Distance-Based Constant-Speed Animation
Instead of interpolating by array indices (which causes erratic car speed due to unevenly spaced polyline points), the engine uses **cumulative Haversine distance**:
* Pre-computes cumulative segment distances $D_0, D_1, \dots, D_n$.
* Animates traversal distance $d_{\text{covered}}$ over time:
  $$\Delta d = V_{\text{base}} \times \text{speedMultiplier} \times \Delta t$$
* Finds segment index $k$ where $D_k \le d_{\text{covered}} \le D_{k+1}$ and interpolates position $P(t) = P_k + t(P_{k+1} - P_k)$.

### B. Bearing Calculation & Shortest-Path Rotation
* **Bearing Formula**: Calculated via initial spherical bearing trigonometry normalized to $[0^\circ, 360^\circ]$.
* **Shortest Angle Delta**: When transitioning across the $0^\circ / 360^\circ$ boundary (e.g., $359^\circ \to 1^\circ$), standard linear interpolation causes the marker to spin $358^\circ$ backwards. The engine computes:
  $$\Delta \theta = (\theta_{\text{target}} - \theta_{\text{current}} + 540^\circ) \pmod{360^\circ} - 180^\circ$$
  yielding a $+2^\circ$ forward rotation.

### C. Safeguards Against Duplicate/Very-Close Points
If two consecutive polyline coordinates are identical or less than $1\times 10^{-6}$ meters apart ($D_{k+1} - D_k \le 10^{-6}$), fraction $t$ is forced to $0.0$. This prevents division by zero, `NaN`, or `Infinity` coordinate values.

---

## 7. Android Build Flavors & Base URL Configuration
* **Flavors**: Defined in `android/app/build.gradle.kts` under `productFlavors`:
  * `dev`: `applicationIdSuffix = ".dev"`, app name "NavTrack Dev", displays floating `DEV` badge in UI.
  * `prod`: standard application ID, app name "NavTrack", clean production UI.
* **Flavor Configuration Architecture**: Entrypoints `main_dev.dart` and `main_prod.dart` initialize `AppConfig` singleton with flavor-specific parameters (`appName`, `osrmBaseUrl`, `showDevBadge`). Business logic reads `AppConfig.instance.osrmBaseUrl` without hardcoded URLs.

---

## 8. Production Readiness Considerations
Before deploying to production, the following infrastructure and platform enhancements would be implemented:
1. **Battery Optimization**: Throttle location updates when app enters background or when stationary.
2. **Background Location Service**: Implement Android Foreground Service with ongoing notification if turn-by-turn guidance must continue with screen off.
3. **Dedicated Routing Infrastructure**: Host a self-managed OSRM cluster or Valhalla instance with fallback load balancers, rate-limiting, and cached route polylines.
4. **Off-Route Detection & Recalculation**: Monitor live GPS stream distance to active route polyline; trigger automatic route recalculation when deviation exceeds 50 meters.

---

## 9. Deliberate Timebox Exclusions
To maintain focus on senior architecture, code quality, and required criteria within the timebox:
* Turn-by-turn voice instruction synthesis (TTS) was omitted.
* Custom map tile caching layers (SQLite tile storage) were deferred in favor of standard HTTP tile streaming.
