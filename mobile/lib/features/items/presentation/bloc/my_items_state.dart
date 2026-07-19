part of 'my_items_bloc.dart';

sealed class MyItemsState extends Equatable {
  const MyItemsState();

  @override
  List<Object?> get props => const [];
}

class MyItemsLoading extends MyItemsState {
  const MyItemsLoading();
}

class MyItemsLoaded extends MyItemsState {
  const MyItemsLoaded(this.items, {this.error});

  final List<ItemEntity> items;

  /// One-shot toggle failure to show in a snackbar; list stays usable.
  final String? error;

  @override
  List<Object?> get props => [items, error];
}

class MyItemsError extends MyItemsState {
  const MyItemsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
