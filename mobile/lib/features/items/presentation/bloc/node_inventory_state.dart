part of 'node_inventory_bloc.dart';

sealed class NodeInventoryState extends Equatable {
  const NodeInventoryState();

  @override
  List<Object?> get props => const [];
}

class NodeInventoryLoading extends NodeInventoryState {
  const NodeInventoryLoading();
}

class NodeInventoryLoaded extends NodeInventoryState {
  const NodeInventoryLoaded(this.items);

  final List<ItemEntity> items;

  @override
  List<Object?> get props => [items];
}

class NodeInventoryError extends NodeInventoryState {
  const NodeInventoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
