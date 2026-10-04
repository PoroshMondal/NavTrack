import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/config/flavor_type.dart';
import 'injection/dependency_injection.dart';
import 'presentation/navigation/pages/nav_track_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize(
    const AppConfig(
      appName: 'NavTrack',
      osrmBaseUrl: 'https://router.project-osrm.org',
      flavor: FlavorType.prod,
      showDevBadge: false,
    ),
  );

  await initDependencyInjection();

  runApp(const NavTrackApp());
}

class NavTrackApp extends StatelessWidget {
  const NavTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade800,
          brightness: Brightness.light,
        ),
      ),
      home: const NavTrackPage(),
    );
  }
}
