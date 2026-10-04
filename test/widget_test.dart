import 'package:flutter_test/flutter_test.dart';
import 'package:nav_track/core/config/app_config.dart';
import 'package:nav_track/core/config/flavor_type.dart';
import 'package:nav_track/injection/dependency_injection.dart';
import 'package:nav_track/main.dart';

void main() {
  testWidgets('NavTrackApp launches smoke test', (WidgetTester tester) async {
    AppConfig.initialize(
      const AppConfig(
        appName: 'NavTrack Dev',
        osrmBaseUrl: 'https://router.project-osrm.org',
        flavor: FlavorType.dev,
        showDevBadge: true,
      ),
    );

    await initDependencyInjection();

    await tester.pumpWidget(const NavTrackApp());
    expect(find.byType(NavTrackApp), findsOneWidget);
  });
}
