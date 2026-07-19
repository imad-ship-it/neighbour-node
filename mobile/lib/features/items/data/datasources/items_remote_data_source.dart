import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/item_model.dart';

/// Talks HTTP. Throws [DioException] upward — the repository translates
/// those into [Failure]s (same contract as auth/nodes).
abstract class ItemsRemoteDataSource {
  Future<ItemModel> createItem({
    required String title,
    required String description,
    required String category,
    required String condition,
    required String dailyRate,
    required String depositAmount,
    int? nodeId,
    List<String> imagePaths,
  });

  Future<List<ItemModel>> getNearbyItems({
    required double lat,
    required double lng,
    required double radiusMeters,
    String? category,
    double? maxRate,
    String? storageType,
  });

  Future<List<ItemModel>> getMyItems();

  Future<List<ItemModel>> getNodeInventory(int nodeId);

  Future<ItemModel> setItemAvailability({
    required int itemId,
    required bool isAvailable,
  });
}

class ItemsRemoteDataSourceImpl implements ItemsRemoteDataSource {
  ItemsRemoteDataSourceImpl({required Dio client}) : _dio = client;

  final Dio _dio;

  List<ItemModel> _parseList(List<dynamic>? data) => (data ?? const [])
      .map((json) => ItemModel.fromJson(json as Map<String, dynamic>))
      .toList();

  @override
  Future<ItemModel> createItem({
    required String title,
    required String description,
    required String category,
    required String condition,
    required String dailyRate,
    required String depositAmount,
    int? nodeId,
    List<String> imagePaths = const [],
  }) async {
    final form = FormData.fromMap({
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'daily_rate': dailyRate,
      'deposit_amount': depositAmount,
      'node': ?nodeId,
    });
    for (final path in imagePaths) {
      form.files.add(MapEntry('images', await MultipartFile.fromFile(path)));
    }
    final response =
        await _dio.post<Map<String, dynamic>>(ApiConstants.items, data: form);
    return ItemModel.fromJson(response.data!);
  }

  @override
  Future<List<ItemModel>> getNearbyItems({
    required double lat,
    required double lng,
    required double radiusMeters,
    String? category,
    double? maxRate,
    String? storageType,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.itemsNearby,
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radiusMeters,
        'category': ?category,
        'max_rate': ?maxRate,
        'storage_type': ?storageType,
      },
    );
    return _parseList(response.data);
  }

  @override
  Future<List<ItemModel>> getMyItems() async {
    final response = await _dio.get<List<dynamic>>(ApiConstants.itemsMy);
    return _parseList(response.data);
  }

  @override
  Future<List<ItemModel>> getNodeInventory(int nodeId) async {
    final response =
        await _dio.get<List<dynamic>>(ApiConstants.nodeInventory(nodeId));
    return _parseList(response.data);
  }

  @override
  Future<ItemModel> setItemAvailability({
    required int itemId,
    required bool isAvailable,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '${ApiConstants.items}$itemId/',
      data: {'is_available': isAvailable},
    );
    return ItemModel.fromJson(response.data!);
  }
}
