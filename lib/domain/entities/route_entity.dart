import 'package:equatable/equatable.dart';
import 'coordinate_entity.dart';

class RouteEntity extends Equatable {
  final List<CoordinateEntity> points;
  final double totalDistanceMeters;
  final double totalDurationSeconds;

  const RouteEntity({
    required this.points,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });

  @override
  List<Object?> get props => [
        points,
        totalDistanceMeters,
        totalDurationSeconds,
      ];
}
