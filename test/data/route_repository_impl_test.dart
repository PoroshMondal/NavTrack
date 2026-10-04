import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nav_track/core/error/failures.dart';
import 'package:nav_track/data/datasources/remote/osrm_route_datasource.dart';
import 'package:nav_track/data/models/osrm_route_response.dart';
import 'package:nav_track/data/repositories/route_repository_impl.dart';
import 'package:nav_track/domain/entities/coordinate_entity.dart';

class MockOsrmRouteDataSource extends Mock implements OsrmRouteDataSource {}

void main() {
  late MockOsrmRouteDataSource mockDataSource;
  late RouteRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockOsrmRouteDataSource();
    repository = RouteRepositoryImpl(dataSource: mockDataSource);
  });

  group('RouteRepositoryImpl Stale Request Protection Tests', () {
    const start = CoordinateEntity(latitude: 23.8103, longitude: 90.4125);
    const dest = CoordinateEntity(latitude: 23.8200, longitude: 90.4200);

    test('rejects stale request immediately if newer requestId has already been dispatched', () async {
      // Dispatch request #1
      when(() => mockDataSource.fetchRoute(
            startLat: start.latitude,
            startLng: start.longitude,
            endLat: dest.latitude,
            endLng: dest.longitude,
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const OsrmRouteResponse(
          code: 'Ok',
          geometry: '_p~iF~ps|U',
          distance: 1000.0,
          duration: 100.0,
        );
      });

      // Dispatch request #2 (requestId = 2)
      final future1 = repository.fetchRoute(start: start, destination: dest, requestId: 1);
      final future2 = repository.fetchRoute(start: start, destination: dest, requestId: 2);

      final result1 = await future1;
      final result2 = await future2;

      // Request #1 must return StaleRouteRequestFailure
      expect(result1.isLeft(), isTrue);
      result1.fold(
        (failure) => expect(failure, isA<StaleRouteRequestFailure>()),
        (_) => fail('Request 1 should have failed as stale'),
      );

      // Request #2 succeeds
      expect(result2.isRight(), isTrue);
    });
  });
}
