import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/item_detail_model.dart';
import '../models/item_model.dart';

/// Talks HTTP. Throws [DioException] upward — the repository translates
/// those into [Failure]s (same contract as auth/nodes).
abstract class ItemsRemoteDataSource {
  Future<ItemDetailModel> getItem(int id);

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

  Future<List<ItemDetailModel>> getPendingDonations(int nodeId);

  Future<ItemDetailModel> reviewDonation({
    required int itemId,
    required bool accept,
  });
}

class ItemsRemoteDataSourceImpl implements ItemsRemoteDataSource {
  ItemsRemoteDataSourceImpl({required Dio client}) : _dio = client;

  final Dio _dio;

  List<ItemModel> _parseList(List<dynamic>? data) => (data ?? const [])
      .map((json) => ItemModel.fromJson(json as Map<String, dynamic>))
      .toList();

  @override
  Future<ItemDetailModel> getItem(int id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('${ApiConstants.items}$id/');
    return ItemDetailModel.fromJson(response.data!);
  }

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

  @override
  Future<List<ItemDetailModel>> getPendingDonations(int nodeId) async {
    final response = await _dio
        .get<List<dynamic>>(ApiConstants.nodePendingDonations(nodeId));
    return (response.data ?? const [])
        .map((json) => ItemDetailModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ItemDetailModel> reviewDonation({
    required int itemId,
    required bool accept,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.itemReviewDonation(itemId),
      data: {'action': accept ? 'accept' : 'reject'},
    );
    return ItemDetailModel.fromJson(response.data!);
  }
}
