import 'package:flutter/material.dart';

import '../widgets/nodes_style.dart';

/// Route stub for "View Node" — the full detail page (photos, hours, rating,
/// inventory) is a later Phase 2 task; this keeps the navigation real.
class NodeDetailPage extends StatelessWidget {
  const NodeDetailPage({super.key, required this.nodeId});

  final int nodeId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Node #$nodeId')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kNodeGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warehouse_outlined,
                    size: 48, color: kNodeGold),
              ),
              const SizedBox(height: 24),
              Text(
                'Node details are on the way',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Photos, operating hours and this Node\'s inventory land '
                'later in Phase 2.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
