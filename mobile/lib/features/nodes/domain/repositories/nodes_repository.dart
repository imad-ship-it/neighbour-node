import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/node_detail_entity.dart';
import '../entities/node_entity.dart';

/// Contract implemented by the data layer (mirrors auth's AuthRepository).
abstract class NodesRepository {
  /// Active nodes within [radiusMeters] of the point, nearest first.
  Future<Either<Failure, List<NodeEntity>>> getNearbyNodes({
    required double lat,
    required double lng,
    double radiusMeters,
  });

  /// Full detail for one node (works for pending/inactive nodes too).
  Future<Either<Failure, NodeDetailEntity>> getNode(int id);

  /// Registers a new node (multipart, max 3 photos). On success the backend
  /// promotes the caller to NODE_MANAGER and the node awaits admin approval.
  Future<Either<Failure, NodeDetailEntity>> registerNode({
    required String name,
    required String description,
    required String address,
    required double lat,
    required double lng,
    required int capacity,
    required Map<String, String> operatingHours,
    List<String> photoPaths,
  });

  /// Id of the node this device registered, if any — used by the drawer's
  /// "My Node" entry. TODO(Phase 3+): replace with a backend "my nodes"
  /// endpoint so managers see their node on every device.
  Future<int?> getManagedNodeId();
}
