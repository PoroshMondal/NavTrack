import '../../core/error/exceptions.dart';
import '../../core/utils/polyline_decoder.dart';
import '../../domain/entities/coordinate_entity.dart';
import '../../domain/entities/route_entity.dart';

class OsrmRouteResponse {
  final String code;
  final String geometry;
  final double distance;
  final double duration;

  const OsrmRouteResponse({
    required this.code,
    required this.geometry,
    required this.distance,
    required this.duration,
  });

  factory OsrmRouteResponse.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String? ?? '';
    if (code != 'Ok') {
      throw NoRouteFoundException(
        json['message'] as String? ?? 'No driving route found.',
      );
    }

    final routes = json['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw const NoRouteFoundException('Empty routes array in response');
    }

    final primaryRoute = routes.first as Map<String, dynamic>;
    final geometry = primaryRoute['geometry'] as String?;
    if (geometry == null || geometry.isEmpty) {
      throw const PolylineDecodeException('Empty geometry polyline in route');
    }

    return OsrmRouteResponse(
      code: code,
      geometry: geometry,
      distance: (primaryRoute['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (primaryRoute['duration'] as num?)?.toDouble() ?? 0.0,
    );
  }

  RouteEntity toEntity() {
    final geoPoints = PolylineDecoder.decode(geometry);
    if (geoPoints.isEmpty) {
      throw const PolylineDecodeException('Decoded polyline contains zero coordinates');
    }

    final points = geoPoints
        .map((g) => CoordinateEntity(latitude: g.latitude, longitude: g.longitude))
        .toList();

    return RouteEntity(
      points: points,
      totalDistanceMeters: distance,
      totalDurationSeconds: duration,
    );
  }
}
