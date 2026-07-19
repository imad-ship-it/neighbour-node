import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/item_entity.dart';
import '../repositories/items_repository.dart';

class SetItemAvailability
    implements UseCase<ItemEntity, SetAvailabilityParams> {
  const SetItemAvailability(this._repository);

  final ItemsRepository _repository;

  @override
  Future<Either<Failure, ItemEntity>> call(SetAvailabilityParams params) =>
      _repository.setItemAvailability(
        itemId: params.itemId,
        isAvailable: params.isAvailable,
      );
}

class SetAvailabilityParams extends Equatable {
  const SetAvailabilityParams({
    required this.itemId,
    required this.isAvailable,
  });

  final int itemId;
  final bool isAvailable;

  @override
  List<Object?> get props => [itemId, isAvailable];
}
