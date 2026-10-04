import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../data/datasources/native/native_location_datasource.dart';
import '../data/datasources/remote/osrm_route_datasource.dart';
import '../data/repositories/location_repository_impl.dart';
import '../data/repositories/route_repository_impl.dart';
import '../domain/repositories/location_repository.dart';
import '../domain/repositories/route_repository.dart';
import '../domain/usecases/calculate_bearing.dart';
import '../domain/usecases/check_location_permission.dart';
import '../domain/usecases/fetch_route.dart';
import '../domain/usecases/get_current_location.dart';
import '../domain/usecases/interpolate_route.dart';
import '../domain/usecases/observe_location.dart';
import '../domain/usecases/open_app_settings_usecase.dart';
import '../domain/usecases/request_location_permission.dart';
import '../presentation/location/cubit/location_cubit.dart';
import '../presentation/map/cubit/map_cubit.dart';
import '../presentation/navigation/cubit/navigation_cubit.dart';
import '../presentation/route/bloc/route_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencyInjection() async {
  // External
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // Data Sources
  sl.registerLazySingleton<NativeLocationDataSource>(
    () => NativeLocationDataSourceImpl(),
  );
  sl.registerLazySingleton<OsrmRouteDataSource>(
    () => OsrmRouteDataSourceImpl(client: sl()),
  );

  // Repositories
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<RouteRepository>(
    () => RouteRepositoryImpl(dataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetCurrentLocation(sl()));
  sl.registerLazySingleton(() => ObserveLocation(sl()));
  sl.registerLazySingleton(() => CheckLocationPermission(sl()));
  sl.registerLazySingleton(() => RequestLocationPermission(sl()));
  sl.registerLazySingleton(() => OpenAppSettingsUseCase(sl()));
  sl.registerLazySingleton(() => FetchRoute(sl()));
  sl.registerLazySingleton(() => CalculateBearing());
  sl.registerLazySingleton(() => InterpolateRoute());

  // BLoCs / Cubits
  sl.registerFactory(() => LocationCubit(
        getCurrentLocationUseCase: sl(),
        observeLocationUseCase: sl(),
        checkPermissionUseCase: sl(),
        requestPermissionUseCase: sl(),
        openAppSettingsUseCase: sl(),
      ));

  sl.registerFactory(() => RouteBloc(
        fetchRouteUseCase: sl(),
      ));

  sl.registerFactory(() => NavigationCubit(
        interpolateRouteUseCase: sl(),
      ));

  sl.registerFactory(() => MapCubit());
}
