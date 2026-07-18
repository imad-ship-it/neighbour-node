import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/node_detail_entity.dart';
import '../repositories/nodes_repository.dart';

class GetNodeDetail implements UseCase<NodeDetailEntity, NodeDetailParams> {
  const GetNodeDetail(this._repository);

  final NodesRepository _repository;

  @override
  Future<Either<Failure, NodeDetailEntity>> call(NodeDetailParams params) =>
      _repository.getNode(params.nodeId);
}

class NodeDetailParams extends Equatable {
  const NodeDetailParams(this.nodeId);

  final int nodeId;

  @override
  List<Object?> get props => [nodeId];
}
