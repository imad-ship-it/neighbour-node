part of 'node_detail_bloc.dart';

sealed class NodeDetailState extends Equatable {
  const NodeDetailState();

  @override
  List<Object?> get props => const [];
}

class NodeDetailLoading extends NodeDetailState {
  const NodeDetailLoading();
}

class NodeDetailLoaded extends NodeDetailState {
  const NodeDetailLoaded(this.node);

  final NodeDetailEntity node;

  @override
  List<Object?> get props => [node];
}

class NodeDetailError extends NodeDetailState {
  const NodeDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
