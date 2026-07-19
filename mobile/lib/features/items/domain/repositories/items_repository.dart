import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/item_detail_entity.dart';
import '../entities/item_entity.dart';

/// Contract implemented by the data layer (mirrors NodesRepository).
abstract class ItemsRepository {
  /// Full detail for one item (any authenticated user).
  Future<Either<Failure, ItemDetailEntity>> getItem(int id);

  /// POST /items/ multipart. `nodeId` set → donation (PENDING_DONATION);
  /// null → personal item, live immediately. Rates travel as strings so the
  /// backend's DecimalField gets exact values.
  Future<Either<Failure, ItemEntity>> createItem({
    required String title,
    required String description,
    required String category,
    required String condition,
    required String dailyRate,
    required String depositAmount,
    int? nodeId,
    List<String> imagePaths,
  });

  /// ACTIVE + available items within [radiusMeters], nearest first.
  /// Optional backend filters: category, maxRate, storageType.
  Future<Either<Failure, List<ItemEntity>>> getNearbyItems({
    required double lat,
    required double lng,
    double radiusMeters,
    String? category,
    double? maxRate,
    String? storageType,
  });

  /// Own listings, every status (incl. pending donations).
  Future<Either<Failure, List<ItemEntity>>> getMyItems();

  /// ACTIVE + available items stored at a node.
  Future<Either<Failure, List<ItemEntity>>> getNodeInventory(int nodeId);

  /// PATCH /items/{id}/ is_available (personal items' rent-out toggle).
  Future<Either<Failure, ItemEntity>> setItemAvailability({
    required int itemId,
    required bool isAvailable,
  });
}
