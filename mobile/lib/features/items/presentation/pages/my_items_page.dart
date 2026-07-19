import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../../nodes/presentation/widgets/nodes_style.dart';
import '../../domain/entities/item_entity.dart';
import '../bloc/my_items_bloc.dart';

/// Own listings with status chips; personal items get a rent-out toggle.
class MyItemsPage extends StatelessWidget {
  const MyItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyItemsBloc>()..add(const LoadMyItems()),
      child: Scaffold(
        appBar: AppBar(title: const Text('My items')),
        body: BlocConsumer<MyItemsBloc, MyItemsState>(
          listener: (context, state) {
            if (state is MyItemsLoaded && state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) => switch (state) {
            MyItemsLoading() =>
              const Center(child: CircularProgressIndicator()),
            MyItemsError(:final message) => _CenteredMessage(
                icon: Icons.cloud_off_outlined,
                text: message,
                actionLabel: 'Retry',
                onAction: () =>
                    context.read<MyItemsBloc>().add(const LoadMyItems()),
              ),
            MyItemsLoaded(:final items) when items.isEmpty =>
              const _CenteredMessage(
                icon: Icons.inventory_2_outlined,
                text: 'Nothing listed yet.\nTap "+" on the map to add '
                    'your first item.',
              ),
            MyItemsLoaded(:final items) => RefreshIndicator(
                onRefresh: () async =>
                    context.read<MyItemsBloc>().add(const LoadMyItems()),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _ItemCard(item: items[index]),
                ),
              ),
          },
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final ItemEntity item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _Thumbnail(url: item.thumbnailUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PKR ${item.dailyRate.toStringAsFixed(0)}/day',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  _StatusChip(item: item),
                ],
              ),
            ),
            if (item.isPersonal && item.isActive)
              Tooltip(
                message:
                    item.isAvailable ? 'Available to rent' : 'Hidden from map',
                child: Switch(
                  value: item.isAvailable,
                  onChanged: (value) => context.read<MyItemsBloc>().add(
                        ToggleItemAvailability(
                          itemId: item.id,
                          isAvailable: value,
                        ),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.item});

  final ItemEntity item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (item.listingStatus) {
      'PENDING_DONATION' => ('Pending', kNodeGold),
      'ACTIVE' => ('Active', Colors.green.shade700),
      'REJECTED' => ('Rejected', scheme.error),
      _ => ('Archived', scheme.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      width: size,
      height: size,
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.handyman_outlined, color: scheme.onSurfaceVariant),
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
