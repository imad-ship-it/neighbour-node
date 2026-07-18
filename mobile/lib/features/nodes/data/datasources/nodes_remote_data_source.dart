import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/node_model.dart';

/// Talks HTTP. Throws [DioException] upward — the repository translates
/// those into [Failure]s (same contract as auth).
abstract class NodesRemoteDataSource {
  Future<List<NodeModel>> getNearbyNodes({
    required double lat,
    required double lng,
    required double radiusMeters,
  });
}

class NodesRemoteDataSourceImpl implements NodesRemoteDataSource {
  NodesRemoteDataSourceImpl({required Dio client}) : _dio = client;

  final Dio _dio;

  @override
  Future<List<NodeModel>> getNearbyNodes({
    required double lat,
    required double lng,
    required double radiusMeters,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.nodesNearby,
      queryParameters: {'lat': lat, 'lng': lng, 'radius': radiusMeters},
    );
    return (response.data ?? const [])
        .map((json) => NodeModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
