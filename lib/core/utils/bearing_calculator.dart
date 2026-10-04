import 'dart:math' as math;

class BearingCalculator {
  /// Calculates initial bearing in degrees (0..360) from start to end coordinate.
  static double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final lat1 = startLat * math.pi / 180;
    final lat2 = endLat * math.pi / 180;
    final dLng = (endLng - startLng) * math.pi / 180;

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = (bearingRad * 180 / math.pi + 360) % 360;

    return bearingDeg;
  }

  /// Calculates the shortest angular delta between currentBearing and targetBearing in degrees (-180..180).
  /// Ensures smooth rotation crossing the 0/360 boundary (e.g., 359° -> 1° = +2°).
  static double shortestAngleDelta(double currentBearing, double targetBearing) {
    final delta = (targetBearing - currentBearing + 540) % 360 - 180;
    return delta;
  }

  /// Interpolates between current and target bearing using factor (0.0 to 1.0).
  static double interpolateBearing(
    double currentBearing,
    double targetBearing,
    double factor,
  ) {
    final clampedFactor = factor.clamp(0.0, 1.0);
    final delta = shortestAngleDelta(currentBearing, targetBearing);
    final interpolated = (currentBearing + delta * clampedFactor) % 360;
    return (interpolated < 0) ? interpolated + 360 : interpolated;
  }
}
