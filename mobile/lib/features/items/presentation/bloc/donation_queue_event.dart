part of 'donation_queue_bloc.dart';

sealed class DonationQueueEvent extends Equatable {
  const DonationQueueEvent();

  @override
  List<Object?> get props => const [];
}

class LoadDonationQueue extends DonationQueueEvent {
  const LoadDonationQueue();
}

class ReviewDonationRequested extends DonationQueueEvent {
  const ReviewDonationRequested({required this.itemId, required this.accept});

  final int itemId;
  final bool accept;

  @override
  List<Object?> get props => [itemId, accept];
}
