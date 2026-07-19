import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/item_entity.dart';
import '../repositories/items_repository.dart';

class GetMyItems implements UseCase<List<ItemEntity>, NoParams> {
  const GetMyItems(this._repository);

  final ItemsRepository _repository;

  @override
  Future<Either<Failure, List<ItemEntity>>> call(NoParams params) =>
      _repository.getMyItems();
}
