import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/item_detail_entity.dart';
import '../repositories/items_repository.dart';

class GetPendingDonations
    implements UseCase<List<ItemDetailEntity>, PendingDonationsParams> {
  const GetPendingDonations(this._repository);

  final ItemsRepository _repository;

  @override
  Future<Either<Failure, List<ItemDetailEntity>>> call(
    PendingDonationsParams params,
  ) =>
      _repository.getPendingDonations(params.nodeId);
}

class PendingDonationsParams extends Equatable {
  const PendingDonationsParams(this.nodeId);

  final int nodeId;

  @override
  List<Object?> get props => [nodeId];
}
