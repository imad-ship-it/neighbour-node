part of 'items_bloc.dart';

sealed class ItemsState extends Equatable {
  const ItemsState();

  @override
  List<Object?> get props => const [];
}

class ItemsInitial extends ItemsState {
  const ItemsInitial();
}

class ItemsLoading extends ItemsState {
  const ItemsLoading();
}

class ItemsLoaded extends ItemsState {
  const ItemsLoaded(this.items);

  final List<ItemEntity> items;

  @override
  List<Object?> get props => [items];
}

class ItemsError extends ItemsState {
  const ItemsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
