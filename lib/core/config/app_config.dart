import 'flavor_type.dart';

class AppConfig {
  final String appName;
  final String osrmBaseUrl;
  final FlavorType flavor;
  final bool showDevBadge;

  const AppConfig({
    required this.appName,
    required this.osrmBaseUrl,
    required this.flavor,
    required this.showDevBadge,
  });

  static late final AppConfig _instance;

  static void initialize(AppConfig config) {
    _instance = config;
  }

  static AppConfig get instance => _instance;

  bool get isDev => flavor == FlavorType.dev;
  bool get isProd => flavor == FlavorType.prod;
}
