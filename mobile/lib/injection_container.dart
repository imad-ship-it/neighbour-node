import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/api_client.dart';
import 'core/network/session_manager.dart';
import 'core/network/token_storage.dart';

final sl = GetIt.instance;

/// Registers core singletons. Feature registrations (blocs, use cases,
/// repositories, datasources) append here as each feature lands.
Future<void> init() async {
  // External
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);

  // Core
  sl.registerLazySingleton(() => TokenStorage(sl()));
  sl.registerLazySingleton(() => SessionManager());
  sl.registerLazySingleton(() => ApiClient(tokenStorage: sl(), sessionManager: sl()));
}
