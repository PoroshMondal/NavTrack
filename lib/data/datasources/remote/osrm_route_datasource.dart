import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/error/exceptions.dart';
import '../../models/osrm_route_response.dart';

abstract class OsrmRouteDataSource {
  Future<OsrmRouteResponse> fetchRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  });
}

class OsrmRouteDataSourceImpl implements OsrmRouteDataSource {
  final http.Client client;

  OsrmRouteDataSourceImpl({required this.client});

  @override
  Future<OsrmRouteResponse> fetchRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final baseUrl = AppConfig.instance.osrmBaseUrl;
    // Note: OSRM format requires startLng,startLat;endLng,endLat
    final url = Uri.parse(
      '$baseUrl/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=polyline',
    );

    try {
      final response = await client.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw const NetworkException('Routing request timed out.');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(response.body);
        return OsrmRouteResponse.fromJson(jsonBody);
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        throw const NoRouteFoundException('No route found for selected coordinates');
      } else {
        throw ServerException('Server error (${response.statusCode})');
      }
    } on FormatException {
      throw const PolylineDecodeException('Invalid response format from routing server');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    }
  }
}
