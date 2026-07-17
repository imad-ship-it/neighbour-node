import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Every domain use case is callable: `final result = await useCase(params);`
/// returning `Either<Failure, T>` — never throwing across layers.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// For use cases that take no arguments: `await useCase(NoParams());`
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
