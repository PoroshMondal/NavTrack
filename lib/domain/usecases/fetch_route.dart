import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/coordinate_entity.dart';
import '../entities/route_entity.dart';
import '../repositories/route_repository.dart';

class FetchRouteParams {
  final CoordinateEntity start;
  final CoordinateEntity destination;
  final int requestId;

  const FetchRouteParams({
    required this.start,
    required this.destination,
    required this.requestId,
  });
}

class FetchRoute {
  final RouteRepository repository;

  FetchRoute(this.repository);

  Future<Either<RouteFailure, RouteEntity>> call(FetchRouteParams params) async {
    return await repository.fetchRoute(
      start: params.start,
      destination: params.destination,
      requestId: params.requestId,
    );
  }
}
