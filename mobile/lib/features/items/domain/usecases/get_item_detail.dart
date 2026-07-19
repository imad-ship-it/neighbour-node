import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/item_detail_entity.dart';
import '../repositories/items_repository.dart';

class GetItemDetail implements UseCase<ItemDetailEntity, ItemDetailParams> {
  const GetItemDetail(this._repository);

  final ItemsRepository _repository;

  @override
  Future<Either<Failure, ItemDetailEntity>> call(ItemDetailParams params) =>
      _repository.getItem(params.itemId);
}

class ItemDetailParams extends Equatable {
  const ItemDetailParams(this.itemId);

  final int itemId;

  @override
  List<Object?> get props => [itemId];
}
