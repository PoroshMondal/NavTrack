import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/entities/coordinate_entity.dart';
import '../../../domain/entities/route_entity.dart';
import '../../location/cubit/location_cubit.dart';
import '../../location/cubit/location_state.dart';
import '../../map/cubit/map_cubit.dart';
import '../../map/cubit/map_state.dart';
import '../../navigation/cubit/navigation_cubit.dart';
import '../../navigation/cubit/navigation_state.dart';
import '../../route/bloc/route_bloc.dart';
import '../../route/bloc/route_state.dart';
import 'car_marker_widget.dart';

class CustomMapView extends StatefulWidget {
  final void Function(CoordinateEntity destination) onDestinationSelected;

  const CustomMapView({
    super.key,
    required this.onDestinationSelected,
  });

  @override
  State<CustomMapView> createState() => _CustomMapViewState();
}

class _CustomMapViewState extends State<CustomMapView> {
  final MapController _mapController = MapController();
  RouteEntity? _cachedRoute;
  CoordinateEntity? _cachedDestination;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MapCubit, MapState>(
          listenWhen: (prev, curr) => curr.recenterTarget != null,
          listener: (context, mapState) {
            if (mapState.recenterTarget != null) {
              _mapController.move(
                LatLng(
                  mapState.recenterTarget!.latitude,
                  mapState.recenterTarget!.longitude,
                ),
                16.0,
              );
              context.read<MapCubit>().clearRecenterTarget();
            }
          },
        ),
        BlocListener<RouteBloc, RouteState>(
          listener: (context, routeState) {
            if (routeState is RouteLoaded) {
              setState(() {
                _cachedRoute = routeState.route;
                _cachedDestination = routeState.destination;
              });
              final polylinePoints = routeState.route.points
                  .map((p) => LatLng(p.latitude, p.longitude))
                  .toList();
              if (polylinePoints.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _mapController.fitCamera(
                    CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(polylinePoints),
                      padding: const EdgeInsets.all(60.0),
                    ),
                  );
                });
              }
            }
          },
        ),
      ],
      child: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, locationState) {
          LatLng initialCenter = const LatLng(23.8103, 90.4125); // Default Dhaka
          if (locationState is LocationLoaded) {
            initialCenter = LatLng(
              locationState.location.latitude,
              locationState.location.longitude,
            );
          }

          return BlocBuilder<NavigationCubit, NavigationState>(
            builder: (context, navState) {
              CoordinateEntity? carPos;
              double carBearing = 0.0;

              if (navState is NavigatingState) {
                carPos = navState.step.currentPosition;
                carBearing = navState.step.currentBearing;
              } else if (navState is NavigationPausedState) {
                carPos = navState.step.currentPosition;
                carBearing = navState.step.currentBearing;
              } else if (navState is NavigationCompletedState) {
                carPos = navState.step.currentPosition;
                carBearing = navState.step.currentBearing;
              }

              // Camera follow logic during car animation
              final isFollowing = context.watch<MapCubit>().state.isFollowingCar;
              if (isFollowing && carPos != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _mapController.move(
                    LatLng(carPos!.latitude, carPos.longitude),
                    _mapController.camera.zoom < 14 ? 16.0 : _mapController.camera.zoom,
                  );
                });
              }

              final polylinePoints = _cachedRoute?.points
                      .map((p) => LatLng(p.latitude, p.longitude))
                      .toList() ??
                  [];

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 15.0,
                  onLongPress: (_, point) {
                    widget.onDestinationSelected(CoordinateEntity(
                      latitude: point.latitude,
                      longitude: point.longitude,
                    ));
                  },
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      context.read<MapCubit>().userPannedMap();
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.navtrack.nav_track',
                    tileProvider: NetworkTileProvider(
                      headers: {
                        'User-Agent': 'NavTrack/1.0 (com.navtrack.nav_track)',
                      },
                    ),
                  ),
                  if (polylinePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: polylinePoints,
                          strokeWidth: 5.0,
                          color: Colors.blue.shade700,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      // User initial location marker
                      if (locationState is LocationLoaded)
                        Marker(
                          point: LatLng(
                            locationState.location.latitude,
                            locationState.location.longitude,
                          ),
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600.withAlpha(200),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),

                      // Selected destination marker
                      if (_cachedDestination != null)
                        Marker(
                          point: LatLng(
                            _cachedDestination!.latitude,
                            _cachedDestination!.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                        ),

                      // Animated car marker
                      if (carPos != null)
                        Marker(
                          point: LatLng(
                            carPos.latitude,
                            carPos.longitude,
                          ),
                          width: 44,
                          height: 44,
                          child: CarMarkerWidget(
                            bearingDegrees: carBearing,
                          ),
                        ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('© OpenStreetMap contributors'),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
