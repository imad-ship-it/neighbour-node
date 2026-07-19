import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/item_detail_entity.dart';
import '../repositories/items_repository.dart';

class ReviewDonation
    implements UseCase<ItemDetailEntity, ReviewDonationParams> {
  const ReviewDonation(this._repository);

  final ItemsRepository _repository;

  @override
  Future<Either<Failure, ItemDetailEntity>> call(
    ReviewDonationParams params,
  ) =>
      _repository.reviewDonation(
        itemId: params.itemId,
        accept: params.accept,
      );
}

class ReviewDonationParams extends Equatable {
  const ReviewDonationParams({required this.itemId, required this.accept});

  final int itemId;
  final bool accept;

  @override
  List<Object?> get props => [itemId, accept];
}
