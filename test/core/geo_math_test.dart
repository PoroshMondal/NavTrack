import 'package:flutter_test/flutter_test.dart';
import 'package:nav_track/core/utils/geo_math.dart';

void main() {
  group('GeoMath Tests', () {
    test('haversineDistance returns 0 for identical points', () {
      final dist = GeoMath.haversineDistance(23.8103, 90.4125, 23.8103, 90.4125);
      expect(dist, equals(0.0));
    });

    test('haversineDistance calculates accurate distance between known points', () {
      // Distance between Dhaka and Chittagong (~215 km)
      final distMeters = GeoMath.haversineDistance(23.8103, 90.4125, 22.3569, 91.7832);
      expect(distMeters / 1000, closeTo(215.0, 10.0));
    });

    test('computeCumulativeDistances produces correct cumulative array', () {
      final points = [
        const GeoPoint(0.0, 0.0),
        const GeoPoint(0.0, 1.0),
        const GeoPoint(0.0, 2.0),
      ];

      final cumDist = GeoMath.computeCumulativeDistances(points);
      expect(cumDist.length, equals(3));
      expect(cumDist[0], equals(0.0));
      expect(cumDist[1], greaterThan(0.0));
      expect(cumDist[2], greaterThan(cumDist[1]));
    });

    test('interpolatePosition safely handles zero-distance duplicate points without division by zero or NaN', () {
      final duplicatePoints = [
        const GeoPoint(23.8103, 90.4125),
        const GeoPoint(23.8103, 90.4125), // Repeated identical point
        const GeoPoint(23.8200, 90.4200),
      ];

      final cumDist = GeoMath.computeCumulativeDistances(duplicatePoints);
      final result = GeoMath.interpolatePosition(
        points: duplicatePoints,
        cumulativeDistances: cumDist,
        targetDistance: 0.0,
      );

      expect(result.latitude.isNaN, isFalse);
      expect(result.longitude.isNaN, isFalse);
      expect(result, equals(duplicatePoints.first));
    });
  });
}
