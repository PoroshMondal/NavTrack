import '../../core/utils/bearing_calculator.dart';
import '../../core/utils/geo_math.dart';
import '../entities/coordinate_entity.dart';
import '../entities/nav_step_entity.dart';
import '../entities/route_entity.dart';

class InterpolateRoute {
  NavStepEntity call({
    required RouteEntity route,
    required double coveredDistanceMeters,
    required double previousBearing,
    required double speedMetersPerSecond,
  }) {
    if (route.points.isEmpty) {
      return const NavStepEntity(
        currentPosition: CoordinateEntity(latitude: 0, longitude: 0),
        currentBearing: 0.0,
        remainingDistanceMeters: 0.0,
        remainingDurationSeconds: 0.0,
        progressFraction: 1.0,
      );
    }

    final totalDistance = route.totalDistanceMeters;
    final clampedCovered = coveredDistanceMeters.clamp(0.0, totalDistance);

    // Convert route coordinates to GeoPoints
    final geoPoints = route.points
        .map((p) => GeoPoint(p.latitude, p.longitude))
        .toList();

    final cumulativeDistances = GeoMath.computeCumulativeDistances(geoPoints);

    // Interpolate position
    final currentGeoPoint = GeoMath.interpolatePosition(
      points: geoPoints,
      cumulativeDistances: cumulativeDistances,
      targetDistance: clampedCovered,
    );

    // Determine target bearing by sampling slightly ahead on the route
    final lookAheadDistance = (clampedCovered + 10.0).clamp(0.0, totalDistance);
    final lookAheadPoint = GeoMath.interpolatePosition(
      points: geoPoints,
      cumulativeDistances: cumulativeDistances,
      targetDistance: lookAheadDistance,
    );

    double targetBearing = previousBearing;
    if (lookAheadPoint != currentGeoPoint) {
      targetBearing = BearingCalculator.calculateBearing(
        currentGeoPoint.latitude,
        currentGeoPoint.longitude,
        lookAheadPoint.latitude,
        lookAheadPoint.longitude,
      );
    }

    // Smoothly rotate bearing using factor 0.35 per tick
    final smoothedBearing = BearingCalculator.interpolateBearing(
      previousBearing,
      targetBearing,
      0.35,
    );

    final remainingDistance = (totalDistance - clampedCovered).clamp(0.0, totalDistance);
    final progressFraction = totalDistance > 0 ? (clampedCovered / totalDistance).clamp(0.0, 1.0) : 1.0;

    // Remaining time = remaining distance / effective speed
    final effectiveSpeed = speedMetersPerSecond <= 0 ? 15.0 : speedMetersPerSecond;
    final remainingDuration = remainingDistance / effectiveSpeed;

    return NavStepEntity(
      currentPosition: CoordinateEntity(
        latitude: currentGeoPoint.latitude,
        longitude: currentGeoPoint.longitude,
      ),
      currentBearing: smoothedBearing,
      remainingDistanceMeters: remainingDistance,
      remainingDurationSeconds: remainingDuration.isNaN || remainingDuration.isInfinite ? 0.0 : remainingDuration,
      progressFraction: progressFraction,
    );
  }
}
