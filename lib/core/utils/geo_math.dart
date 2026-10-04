import 'dart:math' as math;

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

class GeoMath {
  static const double earthRadiusMeters = 6371000.0;

  /// Calculates Haversine distance in meters between two coordinates.
  static double haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    if (lat1 == lat2 && lng1 == lng2) return 0.0;

    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLng = (lng2 - lng1) * math.pi / 180.0;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadiusMeters * c;

    return distance.isNaN || distance.isInfinite ? 0.0 : distance;
  }

  /// Calculates the minimum distance from a point to a route polyline.
  static double minDistanceToPolyline(
    double lat,
    double lng,
    List<GeoPoint> polyline,
  ) {
    if (polyline.isEmpty) return 0.0;
    double minDist = double.infinity;
    for (final point in polyline) {
      final dist = haversineDistance(lat, lng, point.latitude, point.longitude);
      if (dist < minDist) {
        minDist = dist;
      }
    }
    return minDist == double.infinity ? 0.0 : minDist;
  }

  /// Returns cumulative distance list for a list of points.
  /// Result list has same length as points, where cumulative[0] == 0.0.
  static List<double> computeCumulativeDistances(List<GeoPoint> points) {
    if (points.isEmpty) return [];
    final distances = List<double>.filled(points.length, 0.0);

    double total = 0.0;
    for (int i = 1; i < points.length; i++) {
      final segDist = haversineDistance(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
      total += segDist;
      distances[i] = total;
    }
    return distances;
  }

  /// Interpolates position along a list of points given target distance in meters.
  /// Returns interpolated GeoPoint, current segment index, and segment fraction t.
  static GeoPoint interpolatePosition({
    required List<GeoPoint> points,
    required List<double> cumulativeDistances,
    required double targetDistance,
  }) {
    if (points.isEmpty) {
      return const GeoPoint(0.0, 0.0);
    }
    if (points.length == 1) {
      return points.first;
    }

    final totalDistance = cumulativeDistances.last;
    if (targetDistance <= 0.0) {
      return points.first;
    }
    if (targetDistance >= totalDistance) {
      return points.last;
    }

    // Binary search or linear scan for segment index k where cumulativeDistances[k] <= targetDistance <= cumulativeDistances[k+1]
    int k = 0;
    while (k < cumulativeDistances.length - 2 &&
        cumulativeDistances[k + 1] < targetDistance) {
      k++;
    }

    final segStartDist = cumulativeDistances[k];
    final segEndDist = cumulativeDistances[k + 1];
    final segLength = segEndDist - segStartDist;

    if (segLength <= 1e-6) {
      // Very close or identical points, avoid division by zero
      return points[k];
    }

    final t = ((targetDistance - segStartDist) / segLength).clamp(0.0, 1.0);

    final p1 = points[k];
    final p2 = points[k + 1];

    final interpLat = p1.latitude + t * (p2.latitude - p1.latitude);
    final interpLng = p1.longitude + t * (p2.longitude - p1.longitude);

    if (interpLat.isNaN || interpLat.isInfinite || interpLng.isNaN || interpLng.isInfinite) {
      return p1;
    }

    return GeoPoint(interpLat, interpLng);
  }
}
