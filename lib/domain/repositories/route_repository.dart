import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/coordinate_entity.dart';
import '../entities/route_entity.dart';

abstract class RouteRepository {
  Future<Either<RouteFailure, RouteEntity>> fetchRoute({
    required CoordinateEntity start,
    required CoordinateEntity destination,
    required int requestId,
  });
}
