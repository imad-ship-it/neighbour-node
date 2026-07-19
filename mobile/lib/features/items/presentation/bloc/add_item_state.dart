part of 'add_item_bloc.dart';

sealed class AddItemState extends Equatable {
  const AddItemState();

  @override
  List<Object?> get props => const [];
}

class AddItemInitial extends AddItemState {
  const AddItemInitial();
}

class AddItemSubmitting extends AddItemState {
  const AddItemSubmitting();
}

class AddItemSuccess extends AddItemState {
  const AddItemSuccess(this.item);

  final ItemEntity item;

  /// Donations wait in the manager's queue; personal items go live at once.
  bool get isDonation => !item.isPersonal;

  @override
  List<Object?> get props => [item];
}

class AddItemFailure extends AddItemState {
  const AddItemFailure(this.message, {this.fieldErrors = const {}});

  final String message;

  /// DRF per-field validation messages — shown under the matching inputs.
  final Map<String, List<String>> fieldErrors;

  @override
  List<Object?> get props => [message, fieldErrors];
}
