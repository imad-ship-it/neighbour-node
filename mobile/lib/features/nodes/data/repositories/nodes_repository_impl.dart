import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/node_entity.dart';
import '../../domain/repositories/nodes_repository.dart';
import '../datasources/nodes_remote_data_source.dart';

class NodesRepositoryImpl implements NodesRepository {
  const NodesRepositoryImpl(this._remote);

  final NodesRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<NodeEntity>>> getNearbyNodes({
    required double lat,
    required double lng,
    double radiusMeters = 5000,
  }) async {
    try {
      final nodes = await _remote.getNearbyNodes(
        lat: lat,
        lng: lng,
        radiusMeters: radiusMeters,
      );
      return Right(nodes.map((node) => node.toEntity()).toList());
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
