import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Location Failures ---
abstract class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

class LocationPermissionDeniedFailure extends LocationFailure {
  const LocationPermissionDeniedFailure([super.message = 'Location permission was denied.']);
}

class LocationPermissionPermanentlyDeniedFailure extends LocationFailure {
  const LocationPermissionPermanentlyDeniedFailure([
    super.message = 'Location permission permanently denied. Please open Settings to enable.',
  ]);
}

class LocationServicesDisabledFailure extends LocationFailure {
  const LocationServicesDisabledFailure([
    super.message = 'Location services (GPS) are disabled on your device.',
  ]);
}

class LocationTimeoutFailure extends LocationFailure {
  const LocationTimeoutFailure([super.message = 'Timed out waiting for location fix.']);
}

class LocationUnavailableFailure extends LocationFailure {
  const LocationUnavailableFailure([super.message = 'Current location is currently unavailable.']);
}

class UnknownLocationFailure extends LocationFailure {
  const UnknownLocationFailure(super.message);
}

// --- Route Failures ---
abstract class RouteFailure extends Failure {
  const RouteFailure(super.message);
}

class NoRouteFoundFailure extends RouteFailure {
  const NoRouteFoundFailure([super.message = 'No driving route found to selected destination.']);
}

class NetworkFailure extends RouteFailure {
  const NetworkFailure([super.message = 'Network failure. Please check your internet connection.']);
}

class ServerFailure extends RouteFailure {
  const ServerFailure([super.message = 'Routing server returned an error.']);
}

class InvalidPolylineFailure extends RouteFailure {
  const InvalidPolylineFailure([super.message = 'Failed to parse route polyline geometry.']);
}

class StaleRouteRequestFailure extends RouteFailure {
  const StaleRouteRequestFailure([super.message = 'Route request superceded by newer selection.']);
}
