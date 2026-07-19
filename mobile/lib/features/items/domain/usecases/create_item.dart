import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/item_entity.dart';
import '../repositories/items_repository.dart';

class CreateItem implements UseCase<ItemEntity, CreateItemParams> {
  const CreateItem(this._repository);

  final ItemsRepository _repository;

  @override
  Future<Either<Failure, ItemEntity>> call(CreateItemParams params) =>
      _repository.createItem(
        title: params.title,
        description: params.description,
        category: params.category,
        condition: params.condition,
        dailyRate: params.dailyRate,
        depositAmount: params.depositAmount,
        nodeId: params.nodeId,
        imagePaths: params.imagePaths,
      );
}

class CreateItemParams extends Equatable {
  const CreateItemParams({
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.dailyRate,
    required this.depositAmount,
    this.nodeId,
    this.imagePaths = const [],
  });

  final String title;
  final String description;
  final String category;
  final String condition;

  /// Kept as typed strings ("500.00") — money never rides a double.
  final String dailyRate;
  final String depositAmount;
  final int? nodeId;
  final List<String> imagePaths;

  @override
  List<Object?> get props => [
        title,
        description,
        category,
        condition,
        dailyRate,
        depositAmount,
        nodeId,
        imagePaths,
      ];
}
