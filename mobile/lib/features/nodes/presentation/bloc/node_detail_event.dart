part of 'node_detail_bloc.dart';

sealed class NodeDetailEvent extends Equatable {
  const NodeDetailEvent();

  @override
  List<Object?> get props => const [];
}

class LoadNodeDetail extends NodeDetailEvent {
  const LoadNodeDetail(this.nodeId);

  final int nodeId;

  @override
  List<Object?> get props => [nodeId];
}
