import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/item_entity.dart';
import '../bloc/node_inventory_bloc.dart';
import 'items_style.dart';

/// Grid of a Node's ACTIVE + available items, embedded in NodeDetailPage.
/// Each tile opens the item's detail page.
class NodeInventoryGrid extends StatelessWidget {
  const NodeInventoryGrid({super.key, required this.nodeId});

  final int nodeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NodeInventoryBloc>()..add(LoadNodeInventory(nodeId)),
      child: BlocBuilder<NodeInventoryBloc, NodeInventoryState>(
        builder: (context, state) => switch (state) {
          NodeInventoryLoading() => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          NodeInventoryError(:final message) => _InventoryMessage(
              icon: Icons.cloud_off_outlined,
              text: message,
              action: TextButton(
                onPressed: () => context
                    .read<NodeInventoryBloc>()
                    .add(LoadNodeInventory(nodeId)),
                child: const Text('Retry'),
              ),
            ),
          NodeInventoryLoaded(:final items) when items.isEmpty =>
            const _InventoryMessage(
              icon: Icons.inventory_2_outlined,
              text: 'No items stored here yet — donations that the manager '
                  'accepts appear in this inventory.',
            ),
          NodeInventoryLoaded(:final items) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _InventoryTile(item: items[index]),
            ),
        },
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item});

  final ItemEntity item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/items/${item.id}', extra: item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: item.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const _TileFallback(),
                      )
                    : const _TileFallback(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PKR ${item.dailyRate.toStringAsFixed(0)}/day',
                    style: TextStyle(fontSize: 12, color: scheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileFallback extends StatelessWidget {
  const _TileFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kItemBlue.withValues(alpha: 0.1),
      child: const Icon(Icons.handyman_outlined, color: kItemBlue, size: 32),
    );
  }
}

class _InventoryMessage extends StatelessWidget {
  const _InventoryMessage({
    required this.icon,
    required this.text,
    this.action,
  });

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
