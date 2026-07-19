part of 'add_item_bloc.dart';

sealed class AddItemEvent extends Equatable {
  const AddItemEvent();

  @override
  List<Object?> get props => const [];
}

class AddItemSubmitted extends AddItemEvent {
  const AddItemSubmitted(this.params);

  final CreateItemParams params;

  @override
  List<Object?> get props => [params];
}
