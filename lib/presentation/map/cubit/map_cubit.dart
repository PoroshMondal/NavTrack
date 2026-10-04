import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/coordinate_entity.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit() : super(MapState.initial());

  void userPannedMap() {
    if (state.isFollowingCar) {
      emit(state.copyWith(
        isFollowingCar: false,
        userHasPanned: true,
      ));
    }
  }

  void recenterMap(CoordinateEntity target) {
    emit(state.copyWith(
      isFollowingCar: true,
      userHasPanned: false,
      recenterTarget: target,
    ));
  }

  void startFollowing() {
    emit(state.copyWith(
      isFollowingCar: true,
      userHasPanned: false,
    ));
  }

  void clearRecenterTarget() {
    if (state.recenterTarget != null) {
      emit(MapState(
        isFollowingCar: state.isFollowingCar,
        userHasPanned: state.userHasPanned,
        recenterTarget: null,
      ));
    }
  }
}
