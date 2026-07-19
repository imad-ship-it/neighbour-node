part of 'donation_queue_bloc.dart';

sealed class DonationQueueState extends Equatable {
  const DonationQueueState();

  @override
  List<Object?> get props => const [];
}

class DonationQueueLoading extends DonationQueueState {
  const DonationQueueLoading();
}

/// Manager role but no node id stored on this device (registered elsewhere).
class DonationQueueNoNode extends DonationQueueState {
  const DonationQueueNoNode();
}

class DonationQueueLoaded extends DonationQueueState {
  const DonationQueueLoaded(this.items, {this.error});

  final List<ItemDetailEntity> items;

  /// One-shot review failure (after rollback); shown in a snackbar.
  final String? error;

  @override
  List<Object?> get props => [items, error];
}

class DonationQueueError extends DonationQueueState {
  const DonationQueueError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
