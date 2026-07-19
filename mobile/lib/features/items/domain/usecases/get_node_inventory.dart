import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/item_entity.dart';
import '../repositories/items_repository.dart';

class GetNodeInventory
    implements UseCase<List<ItemEntity>, NodeInventoryParams> {
  const GetNodeInventory(this._repository);

  final ItemsRepository _repository;

  @override
  Future<Either<Failure, List<ItemEntity>>> call(NodeInventoryParams params) =>
      _repository.getNodeInventory(params.nodeId);
}

class NodeInventoryParams extends Equatable {
  const NodeInventoryParams(this.nodeId);

  final int nodeId;

  @override
  List<Object?> get props => [nodeId];
}
