import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/coordinate_entity.dart';
import '../../../domain/entities/route_entity.dart';

abstract class RouteState extends Equatable {
  const RouteState();

  @override
  List<Object?> get props => [];
}

class RouteInitial extends RouteState {}

class RouteLoading extends RouteState {
  final int requestId;
  final CoordinateEntity destination;

  const RouteLoading({
    required this.requestId,
    required this.destination,
  });

  @override
  List<Object?> get props => [requestId, destination];
}

class RouteLoaded extends RouteState {
  final RouteEntity route;
  final CoordinateEntity destination;
  final int requestId;

  const RouteLoaded({
    required this.route,
    required this.destination,
    required this.requestId,
  });

  @override
  List<Object?> get props => [route, destination, requestId];
}

class RouteErrorState extends RouteState {
  final RouteFailure failure;
  final int requestId;

  const RouteErrorState({
    required this.failure,
    required this.requestId,
  });

  @override
  List<Object?> get props => [failure, requestId];
}
