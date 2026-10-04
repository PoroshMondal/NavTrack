import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/location_repository.dart';

class CheckLocationPermission {
  final LocationRepository repository;

  CheckLocationPermission(this.repository);

  Future<Either<LocationFailure, String>> call() async {
    return await repository.checkPermission();
  }
}
