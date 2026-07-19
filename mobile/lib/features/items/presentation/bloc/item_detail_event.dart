part of 'item_detail_bloc.dart';

sealed class ItemDetailEvent extends Equatable {
  const ItemDetailEvent();

  @override
  List<Object?> get props => const [];
}

class LoadItemDetail extends ItemDetailEvent {
  const LoadItemDetail(this.itemId);

  final int itemId;

  @override
  List<Object?> get props => [itemId];
}
