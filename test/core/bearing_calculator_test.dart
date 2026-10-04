import 'package:flutter_test/flutter_test.dart';
import 'package:nav_track/core/utils/bearing_calculator.dart';

void main() {
  group('BearingCalculator Tests', () {
    test('calculateBearing returns 0 degrees for due North', () {
      final bearing = BearingCalculator.calculateBearing(0.0, 0.0, 1.0, 0.0);
      expect(bearing, closeTo(0.0, 0.01));
    });

    test('calculateBearing returns 90 degrees for due East', () {
      final bearing = BearingCalculator.calculateBearing(0.0, 0.0, 0.0, 1.0);
      expect(bearing, closeTo(90.0, 0.01));
    });

    test('shortestAngleDelta calculates shortest path crossing 0/360 boundary (359 -> 1)', () {
      final delta = BearingCalculator.shortestAngleDelta(359.0, 1.0);
      expect(delta, equals(2.0));
    });

    test('shortestAngleDelta calculates shortest path backwards (1 -> 359)', () {
      final delta = BearingCalculator.shortestAngleDelta(1.0, 359.0);
      expect(delta, equals(-2.0));
    });

    test('interpolateBearing smoothly rotates without spinning 358 degrees backwards', () {
      final result = BearingCalculator.interpolateBearing(359.0, 1.0, 0.5);
      expect(result, closeTo(0.0, 0.1));
    });
  });
}
