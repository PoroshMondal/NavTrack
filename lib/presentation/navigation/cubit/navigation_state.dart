import 'package:equatable/equatable.dart';
import '../../../domain/entities/nav_step_entity.dart';
import '../../../domain/entities/route_entity.dart';

abstract class NavigationState extends Equatable {
  final double speedMultiplier;

  const NavigationState({this.speedMultiplier = 1.0});

  @override
  List<Object?> get props => [speedMultiplier];
}

class NavigationIdle extends NavigationState {
  const NavigationIdle({super.speedMultiplier = 1.0});
}

class NavigatingState extends NavigationState {
  final NavStepEntity step;
  final RouteEntity route;

  const NavigatingState({
    required this.step,
    required this.route,
    required super.speedMultiplier,
  });

  @override
  List<Object?> get props => [step, route, speedMultiplier];
}

class NavigationPausedState extends NavigationState {
  final NavStepEntity step;
  final RouteEntity route;

  const NavigationPausedState({
    required this.step,
    required this.route,
    required super.speedMultiplier,
  });

  @override
  List<Object?> get props => [step, route, speedMultiplier];
}

class NavigationCompletedState extends NavigationState {
  final NavStepEntity step;
  final RouteEntity route;

  const NavigationCompletedState({
    required this.step,
    required this.route,
    required super.speedMultiplier,
  });

  @override
  List<Object?> get props => [step, route, speedMultiplier];
}
