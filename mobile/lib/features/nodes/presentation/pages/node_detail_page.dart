import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/node_detail_entity.dart';
import '../../domain/entities/node_entity.dart';
import '../bloc/node_detail_bloc.dart';
import '../widgets/nodes_style.dart';

/// Order + labels for the operating-hours table (MASTER_PLAN §4.2 keys).
const _days = [
  ('mon', 'Monday'),
  ('tue', 'Tuesday'),
  ('wed', 'Wednesday'),
  ('thu', 'Thursday'),
  ('fri', 'Friday'),
  ('sat', 'Saturday'),
  ('sun', 'Sunday'),
];

/// Full node detail: photos, rating, hours, manager — GET /nodes/{id}/.
///
/// [initial] is the map-marker entity passed via the route's `extra`; it only
/// feeds the distance chip (the detail endpoint has no distance) and is null
/// on deep links.
class NodeDetailPage extends StatelessWidget {
  const NodeDetailPage({super.key, required this.nodeId, this.initial});

  final int nodeId;
  final NodeEntity? initial;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NodeDetailBloc>()..add(LoadNodeDetail(nodeId)),
      child: Scaffold(
        body: BlocBuilder<NodeDetailBloc, NodeDetailState>(
          builder: (context, state) => switch (state) {
            NodeDetailLoading() =>
              const Center(child: CircularProgressIndicator()),
            NodeDetailError(:final message) => _ErrorView(
                message: message,
                onRetry: () => context
                    .read<NodeDetailBloc>()
                    .add(LoadNodeDetail(nodeId)),
              ),
            NodeDetailLoaded(:final node) => _DetailView(
                node: node,
                distanceMeters: initial?.distanceMeters,
              ),
          },
        ),
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.node, this.distanceMeters});

  final NodeDetailEntity node;
  final double? distanceMeters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 260,
          flexibleSpace:
              FlexibleSpaceBar(background: _PhotoCarousel(urls: node.photoUrls)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        node.name,
                        style: textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _OpenBadge(isOpen: node.isOpenNow),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  node.address,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _RatingStars(rating: node.rating),
                    const SizedBox(width: 8),
                    Text(
                      node.rating > 0
                          ? node.rating.toStringAsFixed(1)
                          : 'Not rated yet',
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (distanceMeters != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.near_me_outlined,
                          size: 16, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${formatDistance(distanceMeters!)} away',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
                if (!node.isActive) ...[
                  const SizedBox(height: 16),
                  _PendingBanner(),
                ],
                if (node.description.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(node.description,
                      style: textTheme.bodyMedium?.copyWith(height: 1.5)),
                ],
                const SizedBox(height: 24),
                _SectionTitle('Operating hours'),
                const SizedBox(height: 8),
                _HoursTable(hours: node.operatingHours),
                const SizedBox(height: 24),
                _SectionTitle('Inventory'),
                const SizedBox(height: 8),
                _StubCard(
                  icon: Icons.inventory_2_outlined,
                  message: 'Browsing this Node\'s items is coming in Phase 3.',
                ),
                const SizedBox(height: 24),
                _SectionTitle('Manager'),
                const SizedBox(height: 8),
                _ManagerCard(manager: node.manager),
                const SizedBox(height: 12),
                Tooltip(
                  message: 'Chat arrives in Phase 5',
                  child: FilledButton.tonalIcon(
                    onPressed: null, // Phase 5 stub
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat with manager'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        color: kNodeGold.withValues(alpha: 0.15),
        child: const Center(
          child: Icon(Icons.warehouse_outlined, size: 72, color: kNodeGold),
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
                Container(color: kNodeGold.withValues(alpha: 0.1)),
            errorWidget: (_, _, _) => Container(
              color: kNodeGold.withValues(alpha: 0.15),
              child: const Icon(Icons.broken_image_outlined,
                  size: 48, color: kNodeGold),
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

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color =
        isOpen ? Colors.green.shade700 : Theme.of(context).colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style:
            TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kNodeGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: kNodeGold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pending approval — this Node becomes visible on the map once '
              'an admin approves it.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: 20,
            color: kNodeGold,
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _HoursTable extends StatelessWidget {
  const _HoursTable({required this.hours});

  final Map<String, String> hours;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final todayIndex = DateTime.now().weekday - 1; // 0 = Monday
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            for (var i = 0; i < _days.length; i++)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: i == todayIndex
                    ? BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                      )
                    : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _days[i].$2,
                        style: TextStyle(
                          fontWeight: i == todayIndex
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      _formatHours(hours[_days[i].$1]),
                      style: TextStyle(
                        fontWeight: i == todayIndex
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: _isClosed(hours[_days[i].$1])
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static bool _isClosed(String? value) =>
      value == null || value.trim().toLowerCase() == 'closed';

  static String _formatHours(String? value) {
    if (_isClosed(value)) return 'Closed';
    return value!.replaceFirst('-', ' – ');
  }
}

class _StubCard extends StatelessWidget {
  const _StubCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

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
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagerCard extends StatelessWidget {
  const _ManagerCard({required this.manager});

  final NodeManagerEntity manager;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          backgroundImage: manager.photoUrl != null
              ? CachedNetworkImageProvider(manager.photoUrl!)
              : null,
          child: manager.photoUrl == null
              ? Icon(Icons.person_outline, color: scheme.onPrimaryContainer)
              : null,
        ),
        title: Text(
          manager.displayName.isNotEmpty ? manager.displayName : 'Node Manager',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.star_rounded, size: 16, color: kNodeGold),
            const SizedBox(width: 4),
            Text(manager.rating > 0
                ? manager.rating.toStringAsFixed(1)
                : 'Not rated yet'),
          ],
        ),
      ),
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
          Align(alignment: Alignment.topLeft, child: BackButton()),
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
