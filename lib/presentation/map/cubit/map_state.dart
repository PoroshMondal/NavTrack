import 'package:equatable/equatable.dart';
import '../../../domain/entities/coordinate_entity.dart';

class MapState extends Equatable {
  final bool isFollowingCar;
  final bool userHasPanned;
  final CoordinateEntity? recenterTarget;

  const MapState({
    required this.isFollowingCar,
    required this.userHasPanned,
    this.recenterTarget,
  });

  factory MapState.initial() => const MapState(
        isFollowingCar: true,
        userHasPanned: false,
        recenterTarget: null,
      );

  MapState copyWith({
    bool? isFollowingCar,
    bool? userHasPanned,
    CoordinateEntity? recenterTarget,
  }) {
    return MapState(
      isFollowingCar: isFollowingCar ?? this.isFollowingCar,
      userHasPanned: userHasPanned ?? this.userHasPanned,
      recenterTarget: recenterTarget ?? this.recenterTarget,
    );
  }

  @override
  List<Object?> get props => [isFollowingCar, userHasPanned, recenterTarget];
}
