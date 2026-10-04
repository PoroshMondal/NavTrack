import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/geo_math.dart';
import '../../../domain/entities/coordinate_entity.dart';
import '../../../domain/entities/route_entity.dart';
import '../../../injection/dependency_injection.dart';
import '../../common/widgets/dev_badge_banner.dart';
import '../../location/cubit/location_cubit.dart';
import '../../location/cubit/location_state.dart';
import '../../location/widgets/location_permission_banner.dart';
import '../../map/cubit/map_cubit.dart';
import '../../map/cubit/map_state.dart';
import '../../map/widgets/custom_map_view.dart';
import '../../map/widgets/recenter_button.dart';
import '../../route/bloc/route_bloc.dart';
import '../../route/bloc/route_event.dart';
import '../../route/bloc/route_state.dart';
import '../cubit/navigation_cubit.dart';
import '../cubit/navigation_state.dart';
import '../widgets/navigation_controls.dart';

class NavTrackPage extends StatelessWidget {
  const NavTrackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<LocationCubit>()..initializeLocation()),
        BlocProvider(create: (_) => sl<RouteBloc>()),
        BlocProvider(create: (_) => sl<NavigationCubit>()),
        BlocProvider(create: (_) => sl<MapCubit>()),
      ],
      child: const _NavTrackView(),
    );
  }
}

class _NavTrackView extends StatefulWidget {
  const _NavTrackView();

  @override
  State<_NavTrackView> createState() => _NavTrackViewState();
}

class _NavTrackViewState extends State<_NavTrackView> with WidgetsBindingObserver {
  Timer? _debounceTimer;
  DateTime? _lastOffRouteTime;
  String? _statusMessage;
  Timer? _statusMessageTimer;
  RouteEntity? _lastLoadedRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _statusMessageTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _showStatusMessage(String message) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
    });
    _statusMessageTimer?.cancel();
    _statusMessageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = null;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final navCubit = context.read<NavigationCubit>();
      if (navCubit.state is NavigatingState) {
        navCubit.pauseNavigation();
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          // Listen to location permission state & off-route detection
          BlocListener<LocationCubit, LocationState>(
            listener: (context, state) {
              if (state is LocationPermissionPermanentlyDeniedState) {
                _showPermissionSettingsDialog(context);
              } else if (state is LocationErrorState) {
                _showStatusMessage(state.failure.message);
              } else if (state is LocationLoaded && state.isLive) {
                final routeState = context.read<RouteBloc>().state;
                if (routeState is RouteLoaded) {
                  final geoPoints = routeState.route.points
                      .map((p) => GeoPoint(p.latitude, p.longitude))
                      .toList();
                  final minDistToRoute = GeoMath.minDistanceToPolyline(
                    state.location.latitude,
                    state.location.longitude,
                    geoPoints,
                  );
                  if (minDistToRoute > 50.0) {
                    final now = DateTime.now();
                    if (_lastOffRouteTime == null ||
                        now.difference(_lastOffRouteTime!) > const Duration(seconds: 10)) {
                      _lastOffRouteTime = now;
                      _showStatusMessage('Off-route detected (>50m). Recalculating...');
                      final newStart = CoordinateEntity(
                        latitude: state.location.latitude,
                        longitude: state.location.longitude,
                      );
                      context.read<RouteBloc>().add(SelectDestinationEvent(
                            start: newStart,
                            destination: routeState.destination,
                          ));
                    }
                  }
                }
              }
            },
          ),

          // Listen to route loading and errors
          BlocListener<RouteBloc, RouteState>(
            listener: (context, state) {
              if (state is RouteErrorState) {
                _showStatusMessage(state.failure.message);
              } else if (state is RouteLoaded) {
                setState(() {
                  _lastLoadedRoute = state.route;
                });
                context.read<MapCubit>().startFollowing();
              }
            },
          ),
        ],
        child: Stack(
          children: [
            // Base Map View (Persistent instance, prevents tile re-generation & blinking)
            CustomMapView(
              onDestinationSelected: (dest) =>
                  _onDestinationSelected(context, dest),
            ),

            // Top Dev Badge Banner (if dev flavor)
            const DevBadgeBanner(),

            // Contextual Location Permission Banner
            BlocBuilder<LocationCubit, LocationState>(
              builder: (context, locState) {
                if (locState is LocationPermissionRequiredState) {
                  return Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: LocationPermissionBanner(
                        onRequestPermission: () {
                          context
                              .read<LocationCubit>()
                              .requestPermissionAndObserve();
                        },
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Top Status Banner & Loading Progress
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BlocBuilder<RouteBloc, RouteState>(
                      builder: (context, routeState) {
                        if (routeState is RouteLoading) {
                          return const LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    if (_statusMessage != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade900.withAlpha(240),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Recenter floating button
            BlocBuilder<MapCubit, MapState>(
              builder: (context, mapState) {
                if (!mapState.userHasPanned) return const SizedBox.shrink();

                final navState = context.watch<NavigationCubit>().state;
                final locationState = context.watch<LocationCubit>().state;

                CoordinateEntity? target;
                if (navState is NavigatingState) {
                  target = navState.step.currentPosition;
                } else if (locationState is LocationLoaded) {
                  target = CoordinateEntity(
                    latitude: locationState.location.latitude,
                    longitude: locationState.location.longitude,
                  );
                }

                if (target == null) return const SizedBox.shrink();

                return Positioned(
                  bottom: 180,
                  right: 16,
                  child: RecenterButton(
                    onPressed: () {
                      context.read<MapCubit>().recenterMap(target!);
                    },
                  ),
                );
              },
            ),

            // Instruction banner when no route is selected
            BlocBuilder<RouteBloc, RouteState>(
              builder: (context, routeState) {
                if (routeState is! RouteLoaded) {
                  return Positioned(
                    bottom: 120,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900.withAlpha(230),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.touch_app, color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Long-press anywhere on the map to select a destination.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Bottom Navigation Controls (Static UI stability with RepaintBoundary)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: BlocBuilder<RouteBloc, RouteState>(
                  builder: (context, routeState) {
                    if (routeState is RouteLoaded) {
                      _lastLoadedRoute = routeState.route;
                    }
                    final route = _lastLoadedRoute;

                    return BlocBuilder<NavigationCubit, NavigationState>(
                      builder: (context, navState) {
                        double remainingDist = route?.totalDistanceMeters ?? 0.0;
                        double remainingDur = route?.totalDurationSeconds ?? 0.0;
                        double speedMult = navState.speedMultiplier;
                        bool isNavigating = false;
                        bool isPaused = false;

                        if (navState is NavigatingState) {
                          remainingDist = navState.step.remainingDistanceMeters;
                          remainingDur = navState.step.remainingDurationSeconds;
                          isNavigating = true;
                        } else if (navState is NavigationPausedState) {
                          remainingDist = navState.step.remainingDistanceMeters;
                          remainingDur = navState.step.remainingDurationSeconds;
                          isPaused = true;
                        }

                        return NavigationControls(
                          hasRoute: route != null,
                          speedMultiplier: speedMult,
                          remainingDistanceMeters: remainingDist,
                          remainingDurationSeconds: remainingDur,
                          isNavigating: isNavigating,
                          isPaused: isPaused,
                          onStart: () {
                            if (route != null) {
                              context
                                  .read<NavigationCubit>()
                                  .startNavigation(route);
                            }
                          },
                          onPause: () {
                            context.read<NavigationCubit>().pauseNavigation();
                          },
                          onResume: () {
                            context.read<NavigationCubit>().resumeNavigation();
                          },
                          onReset: () {
                            context.read<NavigationCubit>().resetNavigation();
                            context.read<RouteBloc>().add(ClearRouteEvent());
                          },
                          onSpeedChanged: (speed) {
                            context
                                .read<NavigationCubit>()
                                .setSpeedMultiplier(speed);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDestinationSelected(BuildContext context, CoordinateEntity dest) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final locationState = context.read<LocationCubit>().state;
      CoordinateEntity start;
      if (locationState is LocationLoaded) {
        start = CoordinateEntity(
          latitude: locationState.location.latitude,
          longitude: locationState.location.longitude,
        );
      } else if (locationState is LocationPermissionRequiredState) {
        context.read<LocationCubit>().requestPermissionAndObserve();
        return;
      } else {
        // Fallback to default start location if GPS fix is still acquiring
        start = const CoordinateEntity(
          latitude: 23.8103,
          longitude: 90.4125,
        );
        _showStatusMessage('Using default start location while acquiring GPS...');
      }
      context.read<RouteBloc>().add(SelectDestinationEvent(
            start: start,
            destination: dest,
          ));
    });
  }

  void _showPermissionSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'NavTrack requires location permission to fetch routes and track navigation. '
          'Please enable location permissions in App Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<LocationCubit>().openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
