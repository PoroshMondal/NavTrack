import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/route_entity.dart';
import '../../../domain/usecases/interpolate_route.dart';
import 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  final InterpolateRoute interpolateRouteUseCase;

  Timer? _timer;
  RouteEntity? _currentRoute;
  double _coveredDistance = 0.0;
  double _previousBearing = 0.0;
  double _speedMultiplier = 1.0;
  static const double _baseSpeedMetersPerSec = 15.0; // ~54 km/h base speed
  static const int _tickIntervalMs = 30; // ~33 FPS animation

  NavigationCubit({required this.interpolateRouteUseCase})
      : super(NavigationIdle());

  void startNavigation(RouteEntity route) {
    _timer?.cancel();
    _currentRoute = route;
    _coveredDistance = 0.0;
    _previousBearing = 0.0;

    _startTicker();
  }

  void pauseNavigation() {
    _timer?.cancel();
    final route = _currentRoute;
    if (route != null && state is NavigatingState) {
      final currentStep = (state as NavigatingState).step;
      emit(NavigationPausedState(
        step: currentStep,
        route: route,
        speedMultiplier: _speedMultiplier,
      ));
    }
  }

  void resumeNavigation() {
    final route = _currentRoute;
    if (route != null && state is NavigationPausedState) {
      _startTicker();
    }
  }

  void resetNavigation() {
    _timer?.cancel();
    _coveredDistance = 0.0;
    _previousBearing = 0.0;
    _currentRoute = null;
    emit(NavigationIdle(speedMultiplier: _speedMultiplier));
  }

  void setSpeedMultiplier(double multiplier) {
    _speedMultiplier = multiplier;
    if (state is NavigatingState) {
      final currentState = state as NavigatingState;
      emit(NavigatingState(
        step: currentState.step,
        route: currentState.route,
        speedMultiplier: _speedMultiplier,
      ));
    } else if (state is NavigationPausedState) {
      final currentState = state as NavigationPausedState;
      emit(NavigationPausedState(
        step: currentState.step,
        route: currentState.route,
        speedMultiplier: _speedMultiplier,
      ));
    } else if (state is NavigationCompletedState) {
      final currentState = state as NavigationCompletedState;
      emit(NavigationCompletedState(
        step: currentState.step,
        route: currentState.route,
        speedMultiplier: _speedMultiplier,
      ));
    } else {
      emit(NavigationIdle(speedMultiplier: _speedMultiplier));
    }
  }

  void _startTicker() {
    final route = _currentRoute;
    if (route == null || route.points.isEmpty) return;

    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: _tickIntervalMs),
      (_) => _onTick(),
    );
  }

  void _onTick() {
    final route = _currentRoute;
    if (route == null || isClosed) {
      _timer?.cancel();
      return;
    }

    final effectiveSpeed = _baseSpeedMetersPerSec * _speedMultiplier;
    final deltaDistance = effectiveSpeed * (_tickIntervalMs / 1000.0);
    _coveredDistance += deltaDistance;

    final step = interpolateRouteUseCase(
      route: route,
      coveredDistanceMeters: _coveredDistance,
      previousBearing: _previousBearing,
      speedMetersPerSecond: effectiveSpeed,
    );

    _previousBearing = step.currentBearing;

    if (_coveredDistance >= route.totalDistanceMeters) {
      _timer?.cancel();
      emit(NavigationCompletedState(
        step: step,
        route: route,
        speedMultiplier: _speedMultiplier,
      ));
    } else {
      emit(NavigatingState(
        step: step,
        route: route,
        speedMultiplier: _speedMultiplier,
      ));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
