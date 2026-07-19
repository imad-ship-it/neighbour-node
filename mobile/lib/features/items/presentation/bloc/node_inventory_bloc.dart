import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/item_entity.dart';
import '../../domain/usecases/get_node_inventory.dart';

part 'node_inventory_event.dart';
part 'node_inventory_state.dart';

class NodeInventoryBloc extends Bloc<NodeInventoryEvent, NodeInventoryState> {
  NodeInventoryBloc({required GetNodeInventory inventory})
      : _getNodeInventory = inventory,
        super(const NodeInventoryLoading()) {
    on<LoadNodeInventory>(_onLoad);
  }

  final GetNodeInventory _getNodeInventory;

  Future<void> _onLoad(
    LoadNodeInventory event,
    Emitter<NodeInventoryState> emit,
  ) async {
    emit(const NodeInventoryLoading());
    final result = await _getNodeInventory(NodeInventoryParams(event.nodeId));
    result.fold(
      (failure) => emit(NodeInventoryError(failure.message)),
      (items) => emit(NodeInventoryLoaded(items)),
    );
  }
}
