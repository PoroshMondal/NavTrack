import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../domain/usecases/fetch_route.dart';
import 'route_event.dart';
import 'route_state.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final FetchRoute fetchRouteUseCase;
  int _requestIdCounter = 0;

  RouteBloc({required this.fetchRouteUseCase}) : super(RouteInitial()) {
    on<SelectDestinationEvent>(_onSelectDestination);
    on<ClearRouteEvent>(_onClearRoute);
  }

  Future<void> _onSelectDestination(
    SelectDestinationEvent event,
    Emitter<RouteState> emit,
  ) async {
    _requestIdCounter++;
    final currentRequestId = _requestIdCounter;

    emit(RouteLoading(
      requestId: currentRequestId,
      destination: event.destination,
    ));

    final result = await fetchRouteUseCase(FetchRouteParams(
      start: event.start,
      destination: event.destination,
      requestId: currentRequestId,
    ));

    // Stale Request Guard: Ensure current request is still active before emitting
    if (currentRequestId != _requestIdCounter) {
      return;
    }

    result.fold(
      (failure) {
        if (failure is! StaleRouteRequestFailure) {
          emit(RouteErrorState(
            failure: failure,
            requestId: currentRequestId,
          ));
        }
      },
      (route) {
        emit(RouteLoaded(
          route: route,
          destination: event.destination,
          requestId: currentRequestId,
        ));
      },
    );
  }

  void _onClearRoute(
    ClearRouteEvent event,
    Emitter<RouteState> emit,
  ) {
    _requestIdCounter++; // Invalidates any pending in-flight requests
    emit(RouteInitial());
  }
}
