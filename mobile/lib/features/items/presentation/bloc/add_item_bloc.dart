import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/usecases/create_item.dart';

part 'add_item_event.dart';
part 'add_item_state.dart';

class AddItemBloc extends Bloc<AddItemEvent, AddItemState> {
  AddItemBloc({required CreateItem submitItem})
      : _createItem = submitItem,
        super(const AddItemInitial()) {
    on<AddItemSubmitted>(_onSubmitted);
  }

  final CreateItem _createItem;

  Future<void> _onSubmitted(
    AddItemSubmitted event,
    Emitter<AddItemState> emit,
  ) async {
    emit(const AddItemSubmitting());
    final result = await _createItem(event.params);
    result.fold(
      (failure) => emit(AddItemFailure(
        failure.message,
        fieldErrors:
            failure is ValidationFailure ? failure.fieldErrors : const {},
      )),
      (item) => emit(AddItemSuccess(item)),
    );
  }
}
