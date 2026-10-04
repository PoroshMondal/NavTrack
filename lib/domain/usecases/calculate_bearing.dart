import '../../core/utils/bearing_calculator.dart';
import '../entities/coordinate_entity.dart';

class CalculateBearing {
  double call(CoordinateEntity start, CoordinateEntity end) {
    return BearingCalculator.calculateBearing(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  double interpolate({
    required double currentBearing,
    required double targetBearing,
    required double factor,
  }) {
    return BearingCalculator.interpolateBearing(
      currentBearing,
      targetBearing,
      factor,
    );
  }
}
