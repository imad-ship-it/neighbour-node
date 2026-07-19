import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nodes/domain/repositories/nodes_repository.dart';
import '../../domain/entities/item_detail_entity.dart';
import '../../domain/usecases/get_pending_donations.dart';
import '../../domain/usecases/review_donation.dart';

part 'donation_queue_event.dart';
part 'donation_queue_state.dart';

/// The manager's pending-donations queue (Manage tab).
///
/// Kept as its own single-purpose bloc rather than folded into a future
/// DashboardBloc: Phase 4's dashboard has unrelated state (stats, active
/// transactions) and merging now would couple flows that change for
/// different reasons.
class DonationQueueBloc extends Bloc<DonationQueueEvent, DonationQueueState> {
  DonationQueueBloc({
    required GetPendingDonations pendingDonations,
    required ReviewDonation review,
    required NodesRepository nodesRepo,
  })  : _getPendingDonations = pendingDonations,
        _reviewDonation = review,
        _nodesRepository = nodesRepo,
        super(const DonationQueueLoading()) {
    on<LoadDonationQueue>(_onLoad);
    on<ReviewDonationRequested>(_onReview);
  }

  final GetPendingDonations _getPendingDonations;
  final ReviewDonation _reviewDonation;
  final NodesRepository _nodesRepository;

  Future<void> _onLoad(
    LoadDonationQueue event,
    Emitter<DonationQueueState> emit,
  ) async {
    emit(const DonationQueueLoading());
    final nodeId = await _nodesRepository.getManagedNodeId();
    if (nodeId == null) {
      emit(const DonationQueueNoNode());
      return;
    }
    final result = await _getPendingDonations(PendingDonationsParams(nodeId));
    result.fold(
      (failure) => emit(DonationQueueError(failure.message)),
      (items) => emit(DonationQueueLoaded(items)),
    );
  }

  Future<void> _onReview(
    ReviewDonationRequested event,
    Emitter<DonationQueueState> emit,
  ) async {
    final current = state;
    if (current is! DonationQueueLoaded) return;

    // Optimistic: drop the card immediately; roll back on failure.
    emit(DonationQueueLoaded([
      for (final item in current.items)
        if (item.id != event.itemId) item,
    ]));
    final result = await _reviewDonation(
      ReviewDonationParams(itemId: event.itemId, accept: event.accept),
    );
    result.fold(
      (failure) =>
          emit(DonationQueueLoaded(current.items, error: failure.message)),
      (_) {},
    );
  }
}
