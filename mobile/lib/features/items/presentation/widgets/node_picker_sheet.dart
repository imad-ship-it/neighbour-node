import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/location_service.dart';
import '../../../../injection_container.dart';
import '../../../nodes/domain/entities/node_entity.dart';
import '../../../nodes/presentation/bloc/node_bloc.dart';
import '../../../nodes/presentation/widgets/nodes_style.dart';

/// Bottom-sheet picker of nearby active Nodes (nearest first) for the
/// "Donate to a Node" flow. Pops with the chosen [NodeEntity], or null.
class NodePickerSheet extends StatefulWidget {
  const NodePickerSheet({super.key});

  static Future<NodeEntity?> show(BuildContext context) =>
      showModalBottomSheet<NodeEntity>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => const NodePickerSheet(),
      );

  @override
  State<NodePickerSheet> createState() => _NodePickerSheetState();
}

class _NodePickerSheetState extends State<NodePickerSheet> {
  late final NodeBloc _bloc = sl<NodeBloc>();
  bool _locationFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _locationFailed = false);
    try {
      final position = await sl<LocationService>().getCurrentPosition();
      _bloc.add(LoadNearbyNodes(
        lat: position.latitude,
        lng: position.longitude,
      ));
    } catch (_) {
      if (mounted) setState(() => _locationFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocProvider.value(
      value: _bloc,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'Choose a Node',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: _locationFailed
                  ? _Message(
                      icon: Icons.gps_off_outlined,
                      text: 'Couldn\'t get your location.',
                      actionLabel: 'Retry',
                      onAction: _load,
                    )
                  : BlocBuilder<NodeBloc, NodeState>(
                      builder: (context, state) => switch (state) {
                        NodesInitial() || NodesLoading() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        NodesError(:final message) => _Message(
                            icon: Icons.cloud_off_outlined,
                            text: message,
                            actionLabel: 'Retry',
                            onAction: _load,
                          ),
                        NodesLoaded(:final nodes) when nodes.isEmpty =>
                          const _Message(
                            icon: Icons.explore_off_outlined,
                            text: 'No approved Nodes within 5 km yet.',
                          ),
                        NodesLoaded(:final nodes) => ListView.builder(
                            itemCount: nodes.length,
                            itemBuilder: (context, index) {
                              final node = nodes[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      kNodeGold.withValues(alpha: 0.15),
                                  child: const Icon(Icons.warehouse_outlined,
                                      color: kNodeGold),
                                ),
                                title: Text(node.name),
                                subtitle: Text(
                                  node.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: node.distanceMeters != null
                                    ? Text(
                                        formatDistance(node.distanceMeters!),
                                        style: TextStyle(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : null,
                                onTap: () =>
                                    Navigator.of(context).pop(node),
                              );
                            },
                          ),
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
