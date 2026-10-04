import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/native/native_location_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  final NativeLocationDataSource dataSource;

  LocationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<LocationFailure, LocationEntity>> getCurrentLocation() async {
    try {
      final locationModel = await dataSource.getCurrentLocation();
      return Right(locationModel);
    } on LocationPermissionDeniedException catch (e) {
      return Left(LocationPermissionDeniedFailure(e.message));
    } on LocationPermissionPermanentlyDeniedException catch (e) {
      return Left(LocationPermissionPermanentlyDeniedFailure(e.message));
    } on LocationServicesDisabledException catch (e) {
      return Left(LocationServicesDisabledFailure(e.message));
    } on LocationTimeoutException catch (e) {
      return Left(LocationTimeoutFailure(e.message));
    } on LocationUnavailableException catch (e) {
      return Left(LocationUnavailableFailure(e.message));
    } on PlatformLocationException catch (e) {
      return Left(UnknownLocationFailure(e.message));
    } catch (e) {
      return Left(UnknownLocationFailure(e.toString()));
    }
  }

  @override
  Stream<Either<LocationFailure, LocationEntity>> get locationStream {
    return dataSource.locationStream.map<Either<LocationFailure, LocationEntity>>(
      (locationModel) => Right(locationModel),
    ).handleError((error) {
      if (error is LocationPermissionDeniedException) {
        return Left<LocationFailure, LocationEntity>(
            LocationPermissionDeniedFailure(error.message));
      } else if (error is LocationPermissionPermanentlyDeniedException) {
        return Left<LocationFailure, LocationEntity>(
            LocationPermissionPermanentlyDeniedFailure(error.message));
      } else if (error is LocationServicesDisabledException) {
        return Left<LocationFailure, LocationEntity>(
            LocationServicesDisabledFailure(error.message));
      } else if (error is LocationTimeoutException) {
        return Left<LocationFailure, LocationEntity>(
            LocationTimeoutFailure(error.message));
      } else if (error is LocationUnavailableException) {
        return Left<LocationFailure, LocationEntity>(
            LocationUnavailableFailure(error.message));
      } else {
        return Left<LocationFailure, LocationEntity>(
            UnknownLocationFailure(error.toString()));
      }
    });
  }

  @override
  Future<Either<LocationFailure, String>> checkPermission() async {
    try {
      final status = await dataSource.checkPermission();
      return Right(status);
    } catch (e) {
      return Left(UnknownLocationFailure(e.toString()));
    }
  }

  @override
  Future<Either<LocationFailure, String>> requestPermission() async {
    try {
      final status = await dataSource.requestPermission();
      return Right(status);
    } catch (e) {
      return Left(UnknownLocationFailure(e.toString()));
    }
  }

  @override
  Future<Either<LocationFailure, bool>> openAppSettings() async {
    try {
      final success = await dataSource.openAppSettings();
      return Right(success);
    } catch (e) {
      return Left(UnknownLocationFailure(e.toString()));
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await dataSource.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }
}
