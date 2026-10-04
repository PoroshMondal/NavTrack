import 'package:equatable/equatable.dart';

class RoutePointEntity extends Equatable {
  final double latitude;
  final double longitude;
  final double distanceFromStart;

  const RoutePointEntity({
    required this.latitude,
    required this.longitude,
    required this.distanceFromStart,
  });

  @override
  List<Object?> get props => [latitude, longitude, distanceFromStart];
}
