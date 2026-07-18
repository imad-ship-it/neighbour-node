import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;

import '../constants/api_constants.dart';

/// Outcome of the permission flow, flattened to what the UI cares about.
enum LocationStatus {
  granted,

  /// Device location (GPS) is switched off system-wide.
  serviceDisabled,

  /// Denied this time — re-requesting will show the system prompt again.
  denied,

  /// "Don't ask again" — only the app settings screen can fix this.
  deniedForever,
}

/// Wraps geolocator/permission_handler so the rest of the app never imports
/// them directly, and owns the "send my location to the backend" side effect
/// (MASTER_PLAN §6 Phase 2 Flutter task 1).
class LocationService {
  LocationService({required Dio client}) : _dio = client;

  final Dio _dio;

  /// Runs the full permission flow: service check, then check + request.
  Future<LocationStatus> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationStatus.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        LocationStatus.granted,
      LocationPermission.deniedForever => LocationStatus.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine =>
        LocationStatus.denied,
    };
  }

  /// Call only after [ensurePermission] returned [LocationStatus.granted].
  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

  /// Best-effort PATCH of the fresh coordinates to /auth/me/ so backend geo
  /// queries know where this user is. Failures are swallowed on purpose —
  /// a missed location update must never break the map.
  Future<void> syncLocationToBackend(Position position) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        ApiConstants.me,
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );
    } on DioException {
      // Ignore: purely opportunistic bookkeeping.
    }
  }

  /// App settings page — the only way out of [LocationStatus.deniedForever].
  Future<void> openAppSettings() => permission_handler.openAppSettings();

  /// System location (GPS) settings — for [LocationStatus.serviceDisabled].
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
