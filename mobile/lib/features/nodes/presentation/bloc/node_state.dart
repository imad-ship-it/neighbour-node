part of 'node_bloc.dart';

sealed class NodeState extends Equatable {
  const NodeState();

  @override
  List<Object?> get props => const [];
}

class NodesInitial extends NodeState {
  const NodesInitial();
}

class NodesLoading extends NodeState {
  const NodesLoading();
}

class NodesLoaded extends NodeState {
  const NodesLoaded(this.nodes);

  final List<NodeEntity> nodes;

  @override
  List<Object?> get props => [nodes];
}

class NodesError extends NodeState {
  const NodesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
