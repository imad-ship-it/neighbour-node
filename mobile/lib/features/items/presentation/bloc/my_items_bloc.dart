import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/usecases/get_my_items.dart';
import '../../domain/usecases/set_item_availability.dart';

part 'my_items_event.dart';
part 'my_items_state.dart';

class MyItemsBloc extends Bloc<MyItemsEvent, MyItemsState> {
  MyItemsBloc({
    required GetMyItems myItems,
    required SetItemAvailability toggleAvailability,
  })  : _getMyItems = myItems,
        _setAvailability = toggleAvailability,
        super(const MyItemsLoading()) {
    on<LoadMyItems>(_onLoad);
    on<ToggleItemAvailability>(_onToggle);
  }

  final GetMyItems _getMyItems;
  final SetItemAvailability _setAvailability;

  Future<void> _onLoad(LoadMyItems event, Emitter<MyItemsState> emit) async {
    emit(const MyItemsLoading());
    final result = await _getMyItems(const NoParams());
    result.fold(
      (failure) => emit(MyItemsError(failure.message)),
      (items) => emit(MyItemsLoaded(items)),
    );
  }

  Future<void> _onToggle(
    ToggleItemAvailability event,
    Emitter<MyItemsState> emit,
  ) async {
    final current = state;
    if (current is! MyItemsLoaded) return;

    List<ItemEntity> withItem(ItemEntity replacement) => [
          for (final item in current.items)
            item.id == replacement.id ? replacement : item,
        ];

    final result = await _setAvailability(SetAvailabilityParams(
      itemId: event.itemId,
      isAvailable: event.isAvailable,
    ));
    result.fold(
      // Keep the list; surface the failure without losing the page.
      (failure) => emit(MyItemsLoaded(current.items, error: failure.message)),
      (updated) => emit(MyItemsLoaded(withItem(updated))),
    );
  }
}
