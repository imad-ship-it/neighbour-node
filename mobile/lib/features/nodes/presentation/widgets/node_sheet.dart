import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/node_entity.dart';
import 'nodes_style.dart';

/// Bottom sheet shown when a gold node marker is tapped: identity, quick
/// facts (distance / rating / open now) and the way into the node.
class NodeSheet extends StatelessWidget {
  const NodeSheet({super.key, required this.node});

  final NodeEntity node;

  static Future<void> show(BuildContext context, NodeEntity node) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => NodeSheet(node: node),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _NodeAvatar(thumbnailUrl: node.thumbnailUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        node.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (node.distanceMeters != null)
                  _FactChip(
                    icon: Icons.near_me_outlined,
                    label: formatDistance(node.distanceMeters!),
                    color: scheme.primary,
                  ),
                _FactChip(
                  icon: Icons.star_rounded,
                  label: node.rating > 0
                      ? node.rating.toStringAsFixed(1)
                      : 'Not rated yet',
                  color: kNodeGold,
                ),
                _FactChip(
                  icon: node.isOpenNow
                      ? Icons.door_front_door_outlined
                      : Icons.nightlight_outlined,
                  label: node.isOpenNow ? 'Open now' : 'Closed now',
                  color: node.isOpenNow ? Colors.green.shade700 : scheme.outline,
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/nodes/${node.id}');
              },
              icon: const Icon(Icons.warehouse_outlined),
              label: const Text('View Node'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeAvatar extends StatelessWidget {
  const _NodeAvatar({this.thumbnailUrl});

  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    final url = thumbnailUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => const _AvatarFallback(size: size),
            )
          : const _AvatarFallback(size: size),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: kNodeGold.withValues(alpha: 0.18),
      child: const Icon(Icons.warehouse_outlined, color: kNodeGold, size: 30),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
