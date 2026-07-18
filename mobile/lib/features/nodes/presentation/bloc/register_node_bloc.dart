import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/node_detail_entity.dart';
import '../../domain/usecases/register_node.dart';

part 'register_node_event.dart';
part 'register_node_state.dart';

class RegisterNodeBloc extends Bloc<RegisterNodeEvent, RegisterNodeState> {
  RegisterNodeBloc({required RegisterNode submitNode})
      : _registerNode = submitNode,
        super(const RegisterNodeInitial()) {
    on<RegisterNodeSubmitted>(_onSubmitted);
  }

  final RegisterNode _registerNode;

  Future<void> _onSubmitted(
    RegisterNodeSubmitted event,
    Emitter<RegisterNodeState> emit,
  ) async {
    emit(const RegisterNodeSubmitting());
    final result = await _registerNode(
      RegisterNodeParams(
        name: event.name,
        description: event.description,
        address: event.address,
        lat: event.lat,
        lng: event.lng,
        capacity: event.capacity,
        operatingHours: event.operatingHours,
        photoPaths: event.photoPaths,
      ),
    );
    result.fold(
      (failure) => emit(RegisterNodeFailure(
        failure.message,
        fieldErrors:
            failure is ValidationFailure ? failure.fieldErrors : const {},
      )),
      (node) => emit(RegisterNodeSuccess(node)),
    );
  }
}
