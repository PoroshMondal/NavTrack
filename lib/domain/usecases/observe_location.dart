import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';

class ObserveLocation {
  final LocationRepository repository;

  ObserveLocation(this.repository);

  Stream<Either<LocationFailure, LocationEntity>> call() {
    return repository.locationStream;
  }
}
