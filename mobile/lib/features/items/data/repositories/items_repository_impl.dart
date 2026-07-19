import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/item_detail_entity.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/repositories/items_repository.dart';
import '../datasources/items_remote_data_source.dart';

class ItemsRepositoryImpl implements ItemsRepository {
  const ItemsRepositoryImpl(this._remote);

  final ItemsRemoteDataSource _remote;

  @override
  Future<Either<Failure, ItemDetailEntity>> getItem(int id) =>
      _guard(() async => (await _remote.getItem(id)).toEntity());

  @override
  Future<Either<Failure, ItemEntity>> createItem({
    required String title,
    required String description,
    required String category,
    required String condition,
    required String dailyRate,
    required String depositAmount,
    int? nodeId,
    List<String> imagePaths = const [],
  }) =>
      _guard(() async {
        final item = await _remote.createItem(
          title: title,
          description: description,
          category: category,
          condition: condition,
          dailyRate: dailyRate,
          depositAmount: depositAmount,
          nodeId: nodeId,
          imagePaths: imagePaths,
        );
        return item.toEntity();
      });

  @override
  Future<Either<Failure, List<ItemEntity>>> getNearbyItems({
    required double lat,
    required double lng,
    double radiusMeters = 5000,
    String? category,
    double? maxRate,
    String? storageType,
  }) =>
      _guard(() async {
        final items = await _remote.getNearbyItems(
          lat: lat,
          lng: lng,
          radiusMeters: radiusMeters,
          category: category,
          maxRate: maxRate,
          storageType: storageType,
        );
        return items.map((item) => item.toEntity()).toList();
      });

  @override
  Future<Either<Failure, List<ItemEntity>>> getMyItems() => _guard(() async {
        final items = await _remote.getMyItems();
        return items.map((item) => item.toEntity()).toList();
      });

  @override
  Future<Either<Failure, List<ItemEntity>>> getNodeInventory(int nodeId) =>
      _guard(() async {
        final items = await _remote.getNodeInventory(nodeId);
        return items.map((item) => item.toEntity()).toList();
      });

  @override
  Future<Either<Failure, ItemEntity>> setItemAvailability({
    required int itemId,
    required bool isAvailable,
  }) =>
      _guard(() async {
        final item = await _remote.setItemAvailability(
          itemId: itemId,
          isAvailable: isAvailable,
        );
        return item.toEntity();
      });

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
