import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/item_detail_entity.dart';
import '../../domain/usecases/get_item_detail.dart';

part 'item_detail_event.dart';
part 'item_detail_state.dart';

class ItemDetailBloc extends Bloc<ItemDetailEvent, ItemDetailState> {
  ItemDetailBloc({required GetItemDetail itemDetail})
      : _getItemDetail = itemDetail,
        super(const ItemDetailLoading()) {
    on<LoadItemDetail>(_onLoad);
  }

  final GetItemDetail _getItemDetail;

  Future<void> _onLoad(
    LoadItemDetail event,
    Emitter<ItemDetailState> emit,
  ) async {
    emit(const ItemDetailLoading());
    final result = await _getItemDetail(ItemDetailParams(event.itemId));
    result.fold(
      (failure) => emit(ItemDetailError(failure.message)),
      (item) => emit(ItemDetailLoaded(item)),
    );
  }
}
