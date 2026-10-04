import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/location_repository.dart';

class OpenAppSettingsUseCase {
  final LocationRepository repository;

  OpenAppSettingsUseCase(this.repository);

  Future<Either<LocationFailure, bool>> call() async {
    return await repository.openAppSettings();
  }
}
