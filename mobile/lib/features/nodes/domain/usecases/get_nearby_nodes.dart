import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/node_entity.dart';
import '../repositories/nodes_repository.dart';

class GetNearbyNodes implements UseCase<List<NodeEntity>, NearbyNodesParams> {
  const GetNearbyNodes(this._repository);

  final NodesRepository _repository;

  @override
  Future<Either<Failure, List<NodeEntity>>> call(NearbyNodesParams params) =>
      _repository.getNearbyNodes(
        lat: params.lat,
        lng: params.lng,
        radiusMeters: params.radiusMeters,
      );
}

class NearbyNodesParams extends Equatable {
  const NearbyNodesParams({
    required this.lat,
    required this.lng,
    this.radiusMeters = 5000,
  });

  final double lat;
  final double lng;
  final double radiusMeters;

  @override
  List<Object?> get props => [lat, lng, radiusMeters];
}
