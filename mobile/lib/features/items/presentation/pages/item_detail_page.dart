import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../injection_container.dart';
import '../../../nodes/domain/entities/node_detail_entity.dart'
    show NodeManagerEntity;
import '../../../nodes/presentation/widgets/nodes_style.dart';
import '../../domain/entities/item_detail_entity.dart';
import '../../domain/entities/item_entity.dart';
import '../bloc/item_detail_bloc.dart';
import '../widgets/items_style.dart';

const _categoryLabels = {
  'TOOLS': 'Tools',
  'BOOKS': 'Books',
  'ELECTRONICS': 'Electronics',
  'SPORTS': 'Sports',
  'OTHER': 'Other',
};

const _conditionLabels = {
  'NEW': 'New',
  'GOOD': 'Good',
  'FAIR': 'Fair',
  'POOR': 'Poor',
};

/// Full item view: photos, price, owner, and the way into a rental
/// (Phase 4). [initial] is the map/list entity from the route's `extra`,
/// used only for the distance chip; null on deep links.
class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({super.key, required this.itemId, this.initial});

  final int itemId;
  final ItemEntity? initial;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ItemDetailBloc>()..add(LoadItemDetail(itemId)),
      child: Scaffold(
        body: BlocBuilder<ItemDetailBloc, ItemDetailState>(
          builder: (context, state) => switch (state) {
            ItemDetailLoading() =>
              const Center(child: CircularProgressIndicator()),
            ItemDetailError(:final message) => _ErrorView(
                message: message,
                onRetry: () =>
                    context.read<ItemDetailBloc>().add(LoadItemDetail(itemId)),
              ),
            ItemDetailLoaded(:final item) => _DetailView(
                item: item,
                distanceMeters: initial?.distanceMeters,
              ),
          },
        ),
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.item, this.distanceMeters});

  final ItemDetailEntity item;
  final double? distanceMeters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 280,
          flexibleSpace:
              FlexibleSpaceBar(background: _PhotoCarousel(urls: item.imageUrls)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.category_outlined,
                      label: _categoryLabels[item.category] ?? item.category,
                      color: kItemBlue,
                    ),
                    _InfoChip(
                      icon: Icons.verified_outlined,
                      label:
                          _conditionLabels[item.condition] ?? item.condition,
                      color: scheme.primary,
                    ),
                    if (distanceMeters != null)
                      _InfoChip(
                        icon: Icons.near_me_outlined,
                        label: formatDistance(distanceMeters!),
                        color: scheme.tertiary,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _PriceCard(item: item),
                if (!item.isRentable) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.block_outlined,
                            size: 20, color: scheme.onErrorContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Currently unavailable to rent.',
                            style: textTheme.bodySmall
                                ?.copyWith(color: scheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(item.description,
                      style: textTheme.bodyMedium?.copyWith(height: 1.5)),
                ],
                if (item.nodeName != null) ...[
                  const SizedBox(height: 20),
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kNodeGold.withValues(alpha: 0.15),
                        child: const Icon(Icons.warehouse_outlined,
                            color: kNodeGold),
                      ),
                      title: Text('Stored at ${item.nodeName}'),
                      subtitle: const Text('Pick up from this Node'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/nodes/${item.nodeId}'),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Owner',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _OwnerCard(owner: item.owner),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: item.isRentable
                      ? () => context.push('/rent-coming-soon')
                      : null,
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text('Request to Rent'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.item});

  final ItemDetailEntity item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'PKR ${item.dailyRate.toStringAsFixed(0)}',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                      children: [
                        TextSpan(
                          text: ' / day',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PKR ${item.depositAmount.toStringAsFixed(0)} refundable deposit',
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.payments_outlined, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.owner});

  final NodeManagerEntity owner;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          backgroundImage: owner.photoUrl != null
              ? CachedNetworkImageProvider(owner.photoUrl!)
              : null,
          child: owner.photoUrl == null
              ? Icon(Icons.person_outline, color: scheme.onPrimaryContainer)
              : null,
        ),
        title: Text(
          owner.displayName.isNotEmpty ? owner.displayName : 'Neighbour',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.star_rounded, size: 16, color: kNodeGold),
            const SizedBox(width: 4),
            Text(owner.rating > 0
                ? owner.rating.toStringAsFixed(1)
                : 'Not rated yet'),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
                color: color, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({required this.urls});

  final List<String> urls;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return Container(
        color: kItemBlue.withValues(alpha: 0.12),
        child: const Center(
          child: Icon(Icons.handyman_outlined, size: 72, color: kItemBlue),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.urls.length,
          onPageChanged: (page) => setState(() => _page = page),
          itemBuilder: (context, index) => CachedNetworkImage(
            imageUrl: widget.urls[index],
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                Container(color: kItemBlue.withValues(alpha: 0.08)),
            errorWidget: (_, _, _) => Container(
              color: kItemBlue.withValues(alpha: 0.12),
              child: const Icon(Icons.broken_image_outlined,
                  size: 48, color: kItemBlue),
            ),
          ),
        ),
        if (widget.urls.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.urls.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Align(alignment: Alignment.topLeft, child: BackButton()),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
