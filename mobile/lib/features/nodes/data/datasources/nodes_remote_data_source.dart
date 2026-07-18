import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/node_detail_model.dart';
import '../models/node_model.dart';

/// Talks HTTP. Throws [DioException] upward — the repository translates
/// those into [Failure]s (same contract as auth).
abstract class NodesRemoteDataSource {
  Future<List<NodeModel>> getNearbyNodes({
    required double lat,
    required double lng,
    required double radiusMeters,
  });

  Future<NodeDetailModel> getNode(int id);

  Future<NodeDetailModel> createNode({
    required String name,
    required String description,
    required String address,
    required double lat,
    required double lng,
    required int capacity,
    required Map<String, String> operatingHours,
    required List<String> photoPaths,
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

  @override
  Future<NodeDetailModel> getNode(int id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('${ApiConstants.nodes}$id/');
    return NodeDetailModel.fromJson(response.data!);
  }

  @override
  Future<NodeDetailModel> createNode({
    required String name,
    required String description,
    required String address,
    required double lat,
    required double lng,
    required int capacity,
    required Map<String, String> operatingHours,
    required List<String> photoPaths,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'description': description,
      'address': address,
      'latitude': lat,
      'longitude': lng,
      'capacity': capacity,
      // Multipart carries strings only; the backend serializer parses JSON.
      'operating_hours': jsonEncode(operatingHours),
    });
    for (final path in photoPaths) {
      form.files.add(MapEntry(
        'photos',
        await MultipartFile.fromFile(path),
      ));
    }
    final response =
        await _dio.post<Map<String, dynamic>>(ApiConstants.nodes, data: form);
    return NodeDetailModel.fromJson(response.data!);
  }
}
