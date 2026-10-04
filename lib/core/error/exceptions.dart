class LocationPermissionDeniedException implements Exception {
  final String message;
  const LocationPermissionDeniedException([this.message = 'Location permission denied']);
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  final String message;
  const LocationPermissionPermanentlyDeniedException([this.message = 'Location permission permanently denied']);
}

class LocationServicesDisabledException implements Exception {
  final String message;
  const LocationServicesDisabledException([this.message = 'Location services are disabled on device']);
}

class LocationTimeoutException implements Exception {
  final String message;
  const LocationTimeoutException([this.message = 'Location request timed out']);
}

class LocationUnavailableException implements Exception {
  final String message;
  const LocationUnavailableException([this.message = 'Location fix unavailable']);
}

class PlatformLocationException implements Exception {
  final String code;
  final String message;
  const PlatformLocationException(this.code, this.message);
}

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error occurred']);
}

class NoRouteFoundException implements Exception {
  final String message;
  const NoRouteFoundException([this.message = 'No driving route found between locations']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network connection failure']);
}

class PolylineDecodeException implements Exception {
  final String message;
  const PolylineDecodeException([this.message = 'Failed to decode route polyline']);
}
