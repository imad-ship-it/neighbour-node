import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/item_detail_entity.dart';
import '../bloc/donation_queue_bloc.dart';
import '../widgets/items_style.dart';

/// Manage tab: the manager's donation queue — accept into inventory or
/// reject (MASTER_PLAN §4.3 donation flow).
class PendingDonationsPage extends StatelessWidget {
  const PendingDonationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DonationQueueBloc>()..add(const LoadDonationQueue()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Manage')),
        body: BlocConsumer<DonationQueueBloc, DonationQueueState>(
          listener: (context, state) {
            if (state is DonationQueueLoaded && state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) => switch (state) {
            DonationQueueLoading() =>
              const Center(child: CircularProgressIndicator()),
            DonationQueueNoNode() => const _CenteredMessage(
                icon: Icons.warehouse_outlined,
                text: 'No Node is linked on this device.\nRegister a Node '
                    '(or reopen the app on the device you registered with).',
              ),
            DonationQueueError(:final message) => _CenteredMessage(
                icon: Icons.cloud_off_outlined,
                text: message,
                actionLabel: 'Retry',
                onAction: () => context
                    .read<DonationQueueBloc>()
                    .add(const LoadDonationQueue()),
              ),
            DonationQueueLoaded(:final items) when items.isEmpty =>
              const _CenteredMessage(
                icon: Icons.volunteer_activism_outlined,
                text: 'No pending donations',
              ),
            DonationQueueLoaded(:final items) => RefreshIndicator(
                onRefresh: () async => context
                    .read<DonationQueueBloc>()
                    .add(const LoadDonationQueue()),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _DonationCard(item: items[index]),
                ),
              ),
          },
        ),
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  const _DonationCard({required this.item});

  final ItemDetailEntity item;

  Future<void> _confirmReject(BuildContext context) async {
    final bloc = context.read<DonationQueueBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject donation?'),
        content: Text(
          '"${item.title}" from ${_donorName(item)} will be marked as '
          'rejected. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(ReviewDonationRequested(itemId: item.id, accept: false));
    }
  }

  static String _donorName(ItemDetailEntity item) =>
      item.owner.displayName.isNotEmpty ? item.owner.displayName : 'a neighbour';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Photo(url: item.imageUrls.isNotEmpty
                    ? item.imageUrls.first
                    : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'From ${_donorName(item)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PKR ${item.dailyRate.toStringAsFixed(0)}/day',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(
                          color: scheme.error.withValues(alpha: 0.5)),
                    ),
                    onPressed: () => _confirmReject(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () => context.read<DonationQueueBloc>().add(
                          ReviewDonationRequested(
                              itemId: item.id, accept: true),
                        ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    const fallback = SizedBox(
      width: size,
      height: size,
      child: ColoredBox(
        color: Color(0x1A2F6ED4), // kItemBlue @ 10%
        child: Icon(Icons.handyman_outlined, color: kItemBlue, size: 28),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => fallback,
            )
          : fallback,
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 10),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
