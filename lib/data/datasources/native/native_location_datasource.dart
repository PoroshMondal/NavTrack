import 'package:flutter/services.dart';
import '../../../core/error/exceptions.dart';
import '../../models/location_model.dart';

abstract class NativeLocationDataSource {
  Future<LocationModel> getCurrentLocation();
  Stream<LocationModel> get locationStream;
  Future<String> checkPermission();
  Future<String> requestPermission();
  Future<bool> openAppSettings();
  Future<bool> isLocationServiceEnabled();
}

class NativeLocationDataSourceImpl implements NativeLocationDataSource {
  static const MethodChannel _methodChannel =
      MethodChannel('com.navtrack/location_method');
  static const EventChannel _eventChannel =
      EventChannel('com.navtrack/location_event');

  Stream<LocationModel>? _locationStreamInstance;

  @override
  Future<LocationModel> getCurrentLocation() async {
    try {
      final result = await _methodChannel.invokeMethod('getCurrentLocation');
      if (result is Map) {
        return LocationModel.fromMap(result);
      }
      throw const LocationUnavailableException('Invalid location result format');
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Stream<LocationModel> get locationStream {
    _locationStreamInstance ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) {
          if (event is Map) {
            return LocationModel.fromMap(event);
          }
          throw const LocationUnavailableException('Invalid location stream format');
        })
        .handleError((error) {
          throw _mapException(error);
        });
    return _locationStreamInstance!;
  }

  @override
  Future<String> checkPermission() async {
    try {
      final String result = await _methodChannel.invokeMethod('checkPermission');
      return result;
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<String> requestPermission() async {
    try {
      final String result =
          await _methodChannel.invokeMethod('requestPermission');
      return result;
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      final bool result = await _methodChannel.invokeMethod('openAppSettings');
      return result;
    } catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      final bool result =
          await _methodChannel.invokeMethod('isLocationServiceEnabled');
      return result;
    } catch (e) {
      throw _mapException(e);
    }
  }

  Exception _mapException(Object e) {
    if (e is MissingPluginException) {
      return const LocationUnavailableException('Location services not supported on this platform');
    }
    if (e is PlatformException) {
      switch (e.code) {
        case 'PERMISSION_DENIED':
          return LocationPermissionDeniedException(
              e.message ?? 'Permission denied');
        case 'PERMISSION_PERMANENTLY_DENIED':
          return LocationPermissionPermanentlyDeniedException(
              e.message ?? 'Permission permanently denied');
        case 'LOCATION_DISABLED':
          return LocationServicesDisabledException(
              e.message ?? 'Location services disabled');
        case 'LOCATION_TIMEOUT':
          return LocationTimeoutException(e.message ?? 'Location timeout');
        case 'LOCATION_UNAVAILABLE':
          return LocationUnavailableException(
              e.message ?? 'Location unavailable');
        default:
          return PlatformLocationException(e.code, e.message ?? 'Unknown error');
      }
    }
    return LocationUnavailableException(e.toString());
  }
}
