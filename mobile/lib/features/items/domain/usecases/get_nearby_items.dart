import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/item_entity.dart';
import '../repositories/items_repository.dart';

class GetNearbyItems implements UseCase<List<ItemEntity>, NearbyItemsParams> {
  const GetNearbyItems(this._repository);

  final ItemsRepository _repository;

  @override
  Future<Either<Failure, List<ItemEntity>>> call(NearbyItemsParams params) =>
      _repository.getNearbyItems(
        lat: params.lat,
        lng: params.lng,
        radiusMeters: params.radiusMeters,
        category: params.category,
        maxRate: params.maxRate,
        storageType: params.storageType,
      );
}

class NearbyItemsParams extends Equatable {
  const NearbyItemsParams({
    required this.lat,
    required this.lng,
    this.radiusMeters = 5000,
    this.category,
    this.maxRate,
    this.storageType,
  });

  final double lat;
  final double lng;
  final double radiusMeters;
  final String? category;
  final double? maxRate;
  final String? storageType;

  @override
  List<Object?> get props =>
      [lat, lng, radiusMeters, category, maxRate, storageType];
}
