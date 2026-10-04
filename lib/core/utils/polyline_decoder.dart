import '../error/exceptions.dart';
import 'geo_math.dart';

class PolylineDecoder {
  /// Decodes encoded OSRM polyline string (Precision 5, factor 1e5) into `List<GeoPoint>`.
  static List<GeoPoint> decode(String encodedString, {int precision = 5}) {
    if (encodedString.isEmpty) {
      return [];
    }

    final List<GeoPoint> coordinates = [];
    int index = 0;
    int len = encodedString.length;
    int lat = 0;
    int lng = 0;
    final factor = precision == 6 ? 1e6 : 1e5;

    try {
      while (index < len) {
        int b;
        int shift = 0;
        int result = 0;

        do {
          if (index >= len) break;
          b = encodedString.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);

        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;

        do {
          if (index >= len) break;
          b = encodedString.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);

        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        coordinates.add(GeoPoint(lat / factor, lng / factor));
      }
    } catch (e) {
      throw PolylineDecodeException('Failed to decode polyline: $e');
    }

    return coordinates;
  }
}
