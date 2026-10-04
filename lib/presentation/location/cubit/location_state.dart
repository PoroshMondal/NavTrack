import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/location_entity.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {
  final String message;
  const LocationLoading([this.message = 'Fetching location...']);

  @override
  List<Object?> get props => [message];
}

class LocationLoaded extends LocationState {
  final LocationEntity location;
  final bool isLive;

  const LocationLoaded({
    required this.location,
    this.isLive = false,
  });

  @override
  List<Object?> get props => [location, isLive];
}

class LocationErrorState extends LocationState {
  final LocationFailure failure;

  const LocationErrorState(this.failure);

  @override
  List<Object?> get props => [failure];
}

class LocationPermissionRequiredState extends LocationState {
  final String message;
  const LocationPermissionRequiredState([
    this.message = 'Location permission is required to acquire your current location.',
  ]);

  @override
  List<Object?> get props => [message];
}

class LocationPermissionPermanentlyDeniedState extends LocationState {
  final String message;

  const LocationPermissionPermanentlyDeniedState([
    this.message = 'Location permission permanently denied. Open Settings to enable.',
  ]);

  @override
  List<Object?> get props => [message];
}
