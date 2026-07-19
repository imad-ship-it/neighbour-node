import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/item_entity.dart';
import '../../domain/usecases/get_nearby_items.dart';

part 'items_event.dart';
part 'items_state.dart';

/// Map discovery: nearby PERSONAL items as blue markers. Node items are not
/// individual markers — they live inside their Node's inventory.
class ItemsBloc extends Bloc<ItemsEvent, ItemsState> {
  ItemsBloc({required GetNearbyItems nearbyItems})
      : _getNearbyItems = nearbyItems,
        super(const ItemsInitial()) {
    on<LoadNearbyItems>(_onLoadNearbyItems);
  }

  final GetNearbyItems _getNearbyItems;

  Future<void> _onLoadNearbyItems(
    LoadNearbyItems event,
    Emitter<ItemsState> emit,
  ) async {
    emit(const ItemsLoading());
    final result = await _getNearbyItems(NearbyItemsParams(
      lat: event.lat,
      lng: event.lng,
      radiusMeters: event.radiusMeters,
      category: event.category,
      maxRate: event.maxRate,
      storageType: 'PERSONAL',
    ));
    result.fold(
      (failure) => emit(ItemsError(failure.message)),
      (items) => emit(ItemsLoaded(items)),
    );
  }
}
