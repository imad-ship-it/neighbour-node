import 'package:flutter/foundation.dart' show kIsWeb;

/// API host + endpoint paths.
///
/// Which host reaches the Django dev server depends on where the app runs:
///  * Web / Windows desktop  -> http://localhost:8000  (same machine)
///  * Android emulator       -> http://10.0.2.2:8000   (the emulator maps the
///    host machine's localhost to the special alias 10.0.2.2 — `localhost`
///    inside the emulator is the phone itself, not your PC)
///  * Physical device        -> `http://<your PC's LAN IP>:8000`, e.g.
///    http://192.168.1.20:8000 — find it with `ipconfig`, and run the server
///    with `python manage.py runserver 0.0.0.0:8000` so it accepts LAN
///    connections. Override at build time with:
///    flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1
class ApiConstants {
  ApiConstants._();

  static const String _compileTimeOverride = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_compileTimeOverride.isNotEmpty) return _compileTimeOverride;
    return kIsWeb ? 'http://localhost:8000/api/v1' : 'http://10.0.2.2:8000/api/v1';
  }

  // Auth (MASTER_PLAN §5)
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String refresh = '/auth/refresh/';
  static const String verifyPhone = '/auth/verify-phone/';
  static const String me = '/auth/me/';

  // Nodes (MASTER_PLAN §5)
  static const String nodes = '/nodes/';
  static const String nodesNearby = '/nodes/nearby/';

  // Items (MASTER_PLAN §5)
  static const String items = '/items/';
  static const String itemsNearby = '/items/nearby/';
  static const String itemsMy = '/items/my/';

  static String nodeInventory(int nodeId) => '/nodes/$nodeId/inventory/';
}
