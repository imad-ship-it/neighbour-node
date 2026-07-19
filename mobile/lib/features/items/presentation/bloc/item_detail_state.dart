part of 'item_detail_bloc.dart';

sealed class ItemDetailState extends Equatable {
  const ItemDetailState();

  @override
  List<Object?> get props => const [];
}

class ItemDetailLoading extends ItemDetailState {
  const ItemDetailLoading();
}

class ItemDetailLoaded extends ItemDetailState {
  const ItemDetailLoaded(this.item);

  final ItemDetailEntity item;

  @override
  List<Object?> get props => [item];
}

class ItemDetailError extends ItemDetailState {
  const ItemDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
