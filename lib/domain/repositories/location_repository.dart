import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/location_entity.dart';

abstract class LocationRepository {
  Future<Either<LocationFailure, LocationEntity>> getCurrentLocation();
  Stream<Either<LocationFailure, LocationEntity>> get locationStream;
  Future<Either<LocationFailure, String>> checkPermission();
  Future<Either<LocationFailure, String>> requestPermission();
  Future<Either<LocationFailure, bool>> openAppSettings();
  Future<bool> isLocationServiceEnabled();
}
