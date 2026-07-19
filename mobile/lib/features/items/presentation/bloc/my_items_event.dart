part of 'my_items_bloc.dart';

sealed class MyItemsEvent extends Equatable {
  const MyItemsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadMyItems extends MyItemsEvent {
  const LoadMyItems();
}

/// Rent-out toggle on personal items (PATCH is_available).
class ToggleItemAvailability extends MyItemsEvent {
  const ToggleItemAvailability({
    required this.itemId,
    required this.isAvailable,
  });

  final int itemId;
  final bool isAvailable;

  @override
  List<Object?> get props => [itemId, isAvailable];
}
