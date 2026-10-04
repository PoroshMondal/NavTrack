import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failures.dart';
import '../../../domain/usecases/check_location_permission.dart';
import '../../../domain/usecases/get_current_location.dart';
import '../../../domain/usecases/observe_location.dart';
import '../../../domain/usecases/open_app_settings_usecase.dart';
import '../../../domain/usecases/request_location_permission.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final GetCurrentLocation getCurrentLocationUseCase;
  final ObserveLocation observeLocationUseCase;
  final CheckLocationPermission checkPermissionUseCase;
  final RequestLocationPermission requestPermissionUseCase;
  final OpenAppSettingsUseCase openAppSettingsUseCase;

  StreamSubscription? _locationSubscription;

  LocationCubit({
    required this.getCurrentLocationUseCase,
    required this.observeLocationUseCase,
    required this.checkPermissionUseCase,
    required this.requestPermissionUseCase,
    required this.openAppSettingsUseCase,
  }) : super(LocationInitial());

  Future<void> initializeLocation() async {
    emit(const LocationLoading('Checking location status...'));
    final checkResult = await checkPermissionUseCase();

    await checkResult.fold(
      (failure) async {
        if (!isClosed) emit(LocationErrorState(failure));
      },
      (status) async {
        if (status == 'granted') {
          await fetchOneShotLocation();
          startObservingLocation();
        } else {
          if (!isClosed) emit(const LocationPermissionRequiredState());
        }
      },
    );
  }

  Future<void> requestPermissionAndObserve() async {
    emit(const LocationLoading('Requesting location permissions...'));
    final permResult = await requestPermissionUseCase();

    await permResult.fold(
      (failure) async {
        if (!isClosed) emit(LocationErrorState(failure));
      },
      (status) async {
        if (status == 'granted') {
          await fetchOneShotLocation();
          startObservingLocation();
        } else if (status == 'permanently_denied') {
          if (!isClosed) emit(const LocationPermissionPermanentlyDeniedState());
        } else {
          if (!isClosed) emit(const LocationPermissionRequiredState());
        }
      },
    );
  }

  Future<void> fetchOneShotLocation() async {
    if (isClosed) return;
    emit(const LocationLoading('Acquiring current location...'));

    final result = await getCurrentLocationUseCase();
    result.fold(
      (failure) {
        if (!isClosed) emit(LocationErrorState(failure));
      },
      (location) {
        if (!isClosed) emit(LocationLoaded(location: location, isLive: false));
      },
    );
  }

  void startObservingLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = observeLocationUseCase().listen(
      (result) {
        result.fold(
          (failure) {
            if (!isClosed) emit(LocationErrorState(failure));
          },
          (location) {
            if (!isClosed) {
              emit(LocationLoaded(location: location, isLive: true));
            }
          },
        );
      },
      onError: (error) {
        if (!isClosed) {
          emit(LocationErrorState(UnknownLocationFailure(error.toString())));
        }
      },
    );
  }

  Future<void> openSettings() async {
    await openAppSettingsUseCase();
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
