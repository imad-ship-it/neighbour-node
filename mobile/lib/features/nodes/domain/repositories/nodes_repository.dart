import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/node_entity.dart';

/// Contract implemented by the data layer (mirrors auth's AuthRepository).
abstract class NodesRepository {
  /// Active nodes within [radiusMeters] of the point, nearest first.
  Future<Either<Failure, List<NodeEntity>>> getNearbyNodes({
    required double lat,
    required double lng,
    double radiusMeters,
  });
}
