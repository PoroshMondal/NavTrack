import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/location_repository.dart';

class RequestLocationPermission {
  final LocationRepository repository;

  RequestLocationPermission(this.repository);

  Future<Either<LocationFailure, String>> call() async {
    return await repository.requestPermission();
  }
}
