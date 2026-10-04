import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double bearing;
  final double accuracy;
  final DateTime timestamp;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.bearing,
    required this.accuracy,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        altitude,
        speed,
        bearing,
        accuracy,
        timestamp,
      ];
}
