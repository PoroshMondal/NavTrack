import 'package:equatable/equatable.dart';
import '../../../domain/entities/coordinate_entity.dart';

abstract class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object?> get props => [];
}

class SelectDestinationEvent extends RouteEvent {
  final CoordinateEntity start;
  final CoordinateEntity destination;

  const SelectDestinationEvent({
    required this.start,
    required this.destination,
  });

  @override
  List<Object?> get props => [start, destination];
}

class ClearRouteEvent extends RouteEvent {}
