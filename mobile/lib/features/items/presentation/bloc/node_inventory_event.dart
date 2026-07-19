part of 'node_inventory_bloc.dart';

sealed class NodeInventoryEvent extends Equatable {
  const NodeInventoryEvent();

  @override
  List<Object?> get props => const [];
}

class LoadNodeInventory extends NodeInventoryEvent {
  const LoadNodeInventory(this.nodeId);

  final int nodeId;

  @override
  List<Object?> get props => [nodeId];
}
