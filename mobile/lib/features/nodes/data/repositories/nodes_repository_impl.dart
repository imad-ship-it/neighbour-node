import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/node_detail_entity.dart';
import '../../domain/entities/node_entity.dart';
import '../../domain/repositories/nodes_repository.dart';
import '../datasources/nodes_remote_data_source.dart';

class NodesRepositoryImpl implements NodesRepository {
  const NodesRepositoryImpl(this._remote, this._prefs);

  static const _managedNodeIdKey = 'managed_node_id';

  final NodesRemoteDataSource _remote;
  final SharedPreferences _prefs;

  @override
  Future<Either<Failure, List<NodeEntity>>> getNearbyNodes({
    required double lat,
    required double lng,
    double radiusMeters = 5000,
  }) =>
      _guard(() async {
        final nodes = await _remote.getNearbyNodes(
          lat: lat,
          lng: lng,
          radiusMeters: radiusMeters,
        );
        return nodes.map((node) => node.toEntity()).toList();
      });

  @override
  Future<Either<Failure, NodeDetailEntity>> getNode(int id) =>
      _guard(() async => (await _remote.getNode(id)).toEntity());

  @override
  Future<Either<Failure, NodeDetailEntity>> registerNode({
    required String name,
    required String description,
    required String address,
    required double lat,
    required double lng,
    required int capacity,
    required Map<String, String> operatingHours,
    List<String> photoPaths = const [],
  }) =>
      _guard(() async {
        final node = await _remote.createNode(
          name: name,
          description: description,
          address: address,
          lat: lat,
          lng: lng,
          capacity: capacity,
          operatingHours: operatingHours,
          photoPaths: photoPaths,
        );
        // Remember which node this device manages for the drawer's "My Node".
        await _prefs.setInt(_managedNodeIdKey, node.id);
        return node.toEntity();
      });

  @override
  Future<int?> getManagedNodeId() async => _prefs.getInt(_managedNodeIdKey);

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
