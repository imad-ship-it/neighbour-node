import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/api_client.dart';
import 'core/network/session_manager.dart';
import 'core/network/token_storage.dart';
import 'core/utils/location_service.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/domain/usecases/register_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/items/data/datasources/items_remote_data_source.dart';
import 'features/items/data/repositories/items_repository_impl.dart';
import 'features/items/domain/repositories/items_repository.dart';
import 'features/items/domain/usecases/create_item.dart';
import 'features/items/domain/usecases/get_item_detail.dart';
import 'features/items/domain/usecases/get_my_items.dart';
import 'features/items/domain/usecases/get_nearby_items.dart';
import 'features/items/domain/usecases/get_node_inventory.dart';
import 'features/items/domain/usecases/set_item_availability.dart';
import 'features/items/presentation/bloc/add_item_bloc.dart';
import 'features/items/presentation/bloc/item_detail_bloc.dart';
import 'features/items/presentation/bloc/items_bloc.dart';
import 'features/items/presentation/bloc/my_items_bloc.dart';
import 'features/items/presentation/bloc/node_inventory_bloc.dart';
import 'features/nodes/data/datasources/nodes_remote_data_source.dart';
import 'features/nodes/data/repositories/nodes_repository_impl.dart';
import 'features/nodes/domain/repositories/nodes_repository.dart';
import 'features/nodes/domain/usecases/get_nearby_nodes.dart';
import 'features/nodes/domain/usecases/get_node_detail.dart';
import 'features/nodes/domain/usecases/register_node.dart';
import 'features/nodes/presentation/bloc/node_bloc.dart';
import 'features/nodes/presentation/bloc/node_detail_bloc.dart';
import 'features/nodes/presentation/bloc/register_node_bloc.dart';

final sl = GetIt.instance;

/// Registers dependencies. Pattern per feature (auth is the reference):
/// bloc = factory; use cases, repository, datasource = lazy singletons.
Future<void> init() async {
  // External
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);

  // Core
  sl.registerLazySingleton(() => TokenStorage(sl()));
  sl.registerLazySingleton(() => SessionManager());
  sl.registerLazySingleton(() => ApiClient(tokenStorage: sl(), sessionManager: sl()));
  sl.registerLazySingleton(() => LocationService(client: sl<ApiClient>().dio));

  // Feature: auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl<ApiClient>().dio, tokenStorage: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerFactory(
    () => AuthBloc(
      login: sl(),
      register: sl(),
      restoreSession: sl(),
      signOut: sl(),
      sessionManager: sl(),
    ),
  );

  // Feature: nodes
  sl.registerLazySingleton<NodesRemoteDataSource>(
    () => NodesRemoteDataSourceImpl(client: sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<NodesRepository>(
    () => NodesRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => GetNearbyNodes(sl()));
  sl.registerLazySingleton(() => GetNodeDetail(sl()));
  sl.registerLazySingleton(() => RegisterNode(sl()));
  sl.registerFactory(() => NodeBloc(nearbyNodes: sl()));
  sl.registerFactory(() => NodeDetailBloc(nodeDetail: sl()));
  sl.registerFactory(() => RegisterNodeBloc(submitNode: sl()));

  // Feature: items
  sl.registerLazySingleton<ItemsRemoteDataSource>(
    () => ItemsRemoteDataSourceImpl(client: sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<ItemsRepository>(
    () => ItemsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => CreateItem(sl()));
  sl.registerLazySingleton(() => GetNearbyItems(sl()));
  sl.registerLazySingleton(() => GetMyItems(sl()));
  sl.registerLazySingleton(() => GetNodeInventory(sl()));
  sl.registerLazySingleton(() => GetItemDetail(sl()));
  sl.registerLazySingleton(() => SetItemAvailability(sl()));
  sl.registerFactory(() => AddItemBloc(submitItem: sl()));
  sl.registerFactory(
    () => MyItemsBloc(myItems: sl(), toggleAvailability: sl()),
  );
  sl.registerFactory(() => ItemsBloc(nearbyItems: sl()));
  sl.registerFactory(() => ItemDetailBloc(itemDetail: sl()));
  sl.registerFactory(() => NodeInventoryBloc(inventory: sl()));
}
