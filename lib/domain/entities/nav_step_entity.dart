import 'package:equatable/equatable.dart';
import 'coordinate_entity.dart';

class NavStepEntity extends Equatable {
  final CoordinateEntity currentPosition;
  final double currentBearing;
  final double remainingDistanceMeters;
  final double remainingDurationSeconds;
  final double progressFraction;

  const NavStepEntity({
    required this.currentPosition,
    required this.currentBearing,
    required this.remainingDistanceMeters,
    required this.remainingDurationSeconds,
    required this.progressFraction,
  });

  @override
  List<Object?> get props => [
        currentPosition,
        currentBearing,
        remainingDistanceMeters,
        remainingDurationSeconds,
        progressFraction,
      ];
}
