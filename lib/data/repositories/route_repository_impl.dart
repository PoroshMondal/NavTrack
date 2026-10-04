import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/coordinate_entity.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/route_repository.dart';
import '../datasources/remote/osrm_route_datasource.dart';

class RouteRepositoryImpl implements RouteRepository {
  final OsrmRouteDataSource dataSource;
  int _latestRequestId = 0;

  RouteRepositoryImpl({required this.dataSource});

  @override
  Future<Either<RouteFailure, RouteEntity>> fetchRoute({
    required CoordinateEntity start,
    required CoordinateEntity destination,
    required int requestId,
  }) async {
    // If a newer request has already been initiated, reject this stale request immediately.
    if (requestId < _latestRequestId) {
      return const Left(StaleRouteRequestFailure());
    }

    _latestRequestId = requestId;

    try {
      final response = await dataSource.fetchRoute(
        startLat: start.latitude,
        startLng: start.longitude,
        endLat: destination.latitude,
        endLng: destination.longitude,
      );

      // Verify again upon completion in case another request came in while network call was in flight
      if (requestId < _latestRequestId) {
        return const Left(StaleRouteRequestFailure());
      }

      final routeEntity = response.toEntity();
      return Right(routeEntity);
    } on NoRouteFoundException catch (e) {
      if (requestId < _latestRequestId) return const Left(StaleRouteRequestFailure());
      return Left(NoRouteFoundFailure(e.message));
    } on NetworkException catch (e) {
      if (requestId < _latestRequestId) return const Left(StaleRouteRequestFailure());
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      if (requestId < _latestRequestId) return const Left(StaleRouteRequestFailure());
      return Left(ServerFailure(e.message));
    } on PolylineDecodeException catch (e) {
      if (requestId < _latestRequestId) return const Left(StaleRouteRequestFailure());
      return Left(InvalidPolylineFailure(e.message));
    } catch (e) {
      if (requestId < _latestRequestId) return const Left(StaleRouteRequestFailure());
      return Left(ServerFailure(e.toString()));
    }
  }
}
