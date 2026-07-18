import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/node_detail_entity.dart';
import '../../domain/usecases/get_node_detail.dart';

part 'node_detail_event.dart';
part 'node_detail_state.dart';

class NodeDetailBloc extends Bloc<NodeDetailEvent, NodeDetailState> {
  NodeDetailBloc({required GetNodeDetail nodeDetail})
      : _getNodeDetail = nodeDetail,
        super(const NodeDetailLoading()) {
    on<LoadNodeDetail>(_onLoadNodeDetail);
  }

  final GetNodeDetail _getNodeDetail;

  Future<void> _onLoadNodeDetail(
    LoadNodeDetail event,
    Emitter<NodeDetailState> emit,
  ) async {
    emit(const NodeDetailLoading());
    final result = await _getNodeDetail(NodeDetailParams(event.nodeId));
    result.fold(
      (failure) => emit(NodeDetailError(failure.message)),
      (node) => emit(NodeDetailLoaded(node)),
    );
  }
}
