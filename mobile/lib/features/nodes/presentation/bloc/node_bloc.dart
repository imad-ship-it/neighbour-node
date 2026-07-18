import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/node_entity.dart';
import '../../domain/usecases/get_nearby_nodes.dart';

part 'node_event.dart';
part 'node_state.dart';

class NodeBloc extends Bloc<NodeEvent, NodeState> {
  NodeBloc({required GetNearbyNodes nearbyNodes})
      : _getNearbyNodes = nearbyNodes,
        super(const NodesInitial()) {
    on<LoadNearbyNodes>(_onLoadNearbyNodes);
  }

  final GetNearbyNodes _getNearbyNodes;

  Future<void> _onLoadNearbyNodes(
    LoadNearbyNodes event,
    Emitter<NodeState> emit,
  ) async {
    emit(const NodesLoading());
    final result = await _getNearbyNodes(
      NearbyNodesParams(
        lat: event.lat,
        lng: event.lng,
        radiusMeters: event.radiusMeters,
      ),
    );
    result.fold(
      (failure) => emit(NodesError(failure.message)),
      (nodes) => emit(NodesLoaded(nodes)),
    );
  }
}
