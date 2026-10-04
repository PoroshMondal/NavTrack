import 'package:flutter_test/flutter_test.dart';
import 'package:nav_track/core/utils/polyline_decoder.dart';

void main() {
  group('PolylineDecoder Tests', () {
    test('decode decodes valid OSRM polyline string correctly', () {
      // Sample standard precision 5 polyline string "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
      const polyline = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final points = PolylineDecoder.decode(polyline);

      expect(points.isNotEmpty, isTrue);
      expect(points.first.latitude, closeTo(38.5, 0.1));
      expect(points.first.longitude, closeTo(-120.2, 0.1));
    });

    test('decode handles empty string gracefully', () {
      final points = PolylineDecoder.decode('');
      expect(points, isEmpty);
    });
  });
}
