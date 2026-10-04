import 'package:flutter_test/flutter_test.dart';
import 'package:nav_track/domain/entities/coordinate_entity.dart';
import 'package:nav_track/domain/entities/route_entity.dart';
import 'package:nav_track/domain/usecases/interpolate_route.dart';

void main() {
  group('InterpolateRoute Headless Animation Engine Tests', () {
    late InterpolateRoute useCase;
    late RouteEntity sampleRoute;

    setUp(() {
      useCase = InterpolateRoute();
      sampleRoute = const RouteEntity(
        points: [
          CoordinateEntity(latitude: 23.8103, longitude: 90.4125),
          CoordinateEntity(latitude: 23.8200, longitude: 90.4200),
          CoordinateEntity(latitude: 23.8300, longitude: 90.4300),
        ],
        totalDistanceMeters: 2500.0,
        totalDurationSeconds: 180.0,
      );
    });

    test('interpolates mid-way coordinate and updates remaining distance and ETA', () {
      final step = useCase(
        route: sampleRoute,
        coveredDistanceMeters: 1250.0, // 50% through route
        previousBearing: 0.0,
        speedMetersPerSecond: 15.0,
      );

      expect(step.progressFraction, closeTo(0.5, 0.01));
      expect(step.remainingDistanceMeters, closeTo(1250.0, 1.0));
      expect(step.remainingDurationSeconds, closeTo(83.33, 1.0));
      expect(step.currentPosition.latitude, greaterThan(23.8103));
      expect(step.currentPosition.latitude, lessThan(23.8300));
    });

    test('clamps distance bounds at start and end without crashing or returning NaN', () {
      final startStep = useCase(
        route: sampleRoute,
        coveredDistanceMeters: -100.0, // negative overflow
        previousBearing: 0.0,
        speedMetersPerSecond: 15.0,
      );

      expect(startStep.progressFraction, equals(0.0));
      expect(startStep.currentPosition, equals(sampleRoute.points.first));

      final endStep = useCase(
        route: sampleRoute,
        coveredDistanceMeters: 3000.0, // distance past end
        previousBearing: 0.0,
        speedMetersPerSecond: 15.0,
      );

      expect(endStep.progressFraction, equals(1.0));
      expect(endStep.remainingDistanceMeters, equals(0.0));
    });
  });
}
