import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/location_service.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../items/domain/entities/item_entity.dart';
import '../../../items/presentation/bloc/items_bloc.dart';
import '../../../items/presentation/widgets/items_style.dart';
import '../../domain/entities/node_entity.dart';
import '../../domain/repositories/nodes_repository.dart';
import '../bloc/node_bloc.dart';
import '../widgets/location_gate_view.dart';
import '../widgets/node_sheet.dart';
import '../widgets/nodes_style.dart';

/// Authenticated home: an OpenStreetMap (flutter_map — no API key needed)
/// centred on the user with a translucent 5 km radius circle and gold
/// markers for nearby active Nodes.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

/// Where the page is in the "can we show the map yet" flow.
enum _Gate { checking, denied, deniedForever, serviceOff, ready }

class _MapPageState extends State<MapPage> {
  static const double _radiusMeters = 5000;

  /// Slider ceiling; at this value the max-rate filter is off ("Any price").
  static const double _maxRateAny = 5000;

  final LocationService _location = sl<LocationService>();
  late final NodeBloc _nodeBloc = sl<NodeBloc>();
  late final ItemsBloc _itemsBloc = sl<ItemsBloc>();

  _Gate _gate = _Gate.checking;
  Position? _position;
  final MapController _mapController = MapController();
  String? _categoryFilter;
  double _maxRate = _maxRateAny;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _nodeBloc.close();
    _itemsBloc.close();
    super.dispose();
  }

  /// Permission flow -> current position -> backend location sync -> query.
  Future<void> _bootstrap() async {
    setState(() => _gate = _Gate.checking);
    final status = await _location.ensurePermission();
    if (!mounted) return;
    switch (status) {
      case LocationStatus.denied:
        setState(() => _gate = _Gate.denied);
      case LocationStatus.deniedForever:
        setState(() => _gate = _Gate.deniedForever);
      case LocationStatus.serviceDisabled:
        setState(() => _gate = _Gate.serviceOff);
      case LocationStatus.granted:
        try {
          final position = await _location.getCurrentPosition();
          if (!mounted) return;
          setState(() {
            _position = position;
            _gate = _Gate.ready;
          });
          // Phase 2 task 1: report location to /auth/me/ (best-effort).
          unawaited(_location.syncLocationToBackend(position));
          _loadNodes();
          _loadItems();
        } catch (_) {
          if (mounted) setState(() => _gate = _Gate.serviceOff);
        }
    }
  }

  void _loadNodes() {
    final position = _position;
    if (position == null) return;
    _nodeBloc.add(LoadNearbyNodes(
      lat: position.latitude,
      lng: position.longitude,
      radiusMeters: _radiusMeters,
    ));
  }

  void _loadItems() {
    final position = _position;
    if (position == null) return;
    _itemsBloc.add(LoadNearbyItems(
      lat: position.latitude,
      lng: position.longitude,
      radiusMeters: _radiusMeters,
      category: _categoryFilter,
      maxRate: _maxRate >= _maxRateAny ? null : _maxRate,
    ));
  }

  /// Refresh FAB: re-read the position (it may have changed), re-query.
  Future<void> _refresh() async {
    if (_gate != _Gate.ready) return _bootstrap();
    try {
      final position = await _location.getCurrentPosition();
      if (!mounted) return;
      setState(() => _position = position);
      try {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _mapController.camera.zoom,
        );
      } catch (_) {
        // Map not rendered yet — the new position still recentres it.
      }
      unawaited(_location.syncLocationToBackend(position));
    } catch (_) {
      // Keep the previous position; still re-run the query.
    }
    _loadNodes();
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _nodeBloc),
        BlocProvider.value(value: _itemsBloc),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Nearby Nodes')),
        drawer: const _MapDrawer(),
        body: switch (_gate) {
          _Gate.checking => const Center(child: CircularProgressIndicator()),
          _Gate.denied => LocationGateView(
              icon: Icons.location_off_outlined,
              title: 'Where are you?',
              message:
                  'Neighbor Node shows storerooms and items within 5 km of '
                  'you, so it needs your location to be useful. Nothing is '
                  'shared with other users.',
              onRetry: _bootstrap,
            ),
          _Gate.deniedForever => LocationGateView(
              icon: Icons.location_off_outlined,
              title: 'Location is blocked',
              message:
                  'Location permission is switched off for Neighbor Node. '
                  'Enable it in app settings to see the map of nearby Nodes.',
              onRetry: _bootstrap,
              settingsLabel: 'Open app settings',
              onOpenSettings: _location.openAppSettings,
            ),
          _Gate.serviceOff => LocationGateView(
              icon: Icons.gps_off_outlined,
              title: 'Turn on device location',
              message:
                  'Your phone\'s location (GPS) is off, so we can\'t centre '
                  'the map on you. Switch it on and try again.',
              onRetry: _bootstrap,
              settingsLabel: 'Open location settings',
              onOpenSettings: _location.openLocationSettings,
            ),
          _Gate.ready => Column(
              children: [
                _ItemFilterBar(
                  category: _categoryFilter,
                  maxRate: _maxRate,
                  maxRateCeiling: _maxRateAny,
                  onCategoryChanged: (category) {
                    setState(() => _categoryFilter = category);
                    _loadItems();
                  },
                  onMaxRateChanged: (rate) =>
                      setState(() => _maxRate = rate),
                  onMaxRateChangeEnd: (_) => _loadItems(),
                ),
                Expanded(
                  child: _MapView(
                    position: _position!,
                    radiusMeters: _radiusMeters,
                    mapController: _mapController,
                    onRetryNodes: _loadNodes,
                    onRetryItems: _loadItems,
                    onRefresh: _refresh,
                  ),
                ),
              ],
            ),
        },
        // Phase 3: listing an item is the app's core action — centre stage.
        floatingActionButton: _gate == _Gate.ready
            ? FloatingActionButton.extended(
                heroTag: 'add-item',
                onPressed: () => context.push('/items/add'),
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              )
            : null,
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

/// App menu: profile header, node-manager entry ("Become a Node Manager" or
/// "My Node" once the role flips), and logout.
class _MapDrawer extends StatelessWidget {
  const _MapDrawer();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.person_outline,
                        color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Neighbour',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (user != null)
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (user != null && user.isNodeManager)
              FutureBuilder<int?>(
                future: sl<NodesRepository>().getManagedNodeId(),
                builder: (context, snapshot) {
                  final nodeId = snapshot.data;
                  if (nodeId == null) return const SizedBox.shrink();
                  return ListTile(
                    leading: const Icon(Icons.warehouse_outlined),
                    title: const Text('My Node'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/nodes/$nodeId');
                    },
                  );
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.add_business_outlined),
                title: const Text('Become a Node Manager'),
                subtitle: const Text('Register a community storeroom'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/nodes/register');
                },
              ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('My items'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/items/my');
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () =>
                  context.read<AuthBloc>().add(const LogoutRequested()),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({
    required this.position,
    required this.radiusMeters,
    required this.mapController,
    required this.onRetryNodes,
    required this.onRetryItems,
    required this.onRefresh,
  });

  final Position position;
  final double radiusMeters;
  final MapController mapController;
  final VoidCallback onRetryNodes;
  final VoidCallback onRetryItems;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(position.latitude, position.longitude);
    final nodesState = context.watch<NodeBloc>().state;
    final itemsState = context.watch<ItemsBloc>().state;
    final nodes =
        nodesState is NodesLoaded ? nodesState.nodes : const <NodeEntity>[];
    final items =
        itemsState is ItemsLoaded ? itemsState.items : const <ItemEntity>[];
    final loading = nodesState is NodesLoading || itemsState is ItemsLoading;
    final bothEmpty = nodesState is NodesLoaded &&
        nodes.isEmpty &&
        itemsState is ItemsLoaded &&
        items.isEmpty;
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.neighbornode.neighbor_node',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: radiusMeters,
                  useRadiusInMeter: true,
                  color: kNodeGold.withValues(alpha: 0.07),
                  borderColor: kNodeGold.withValues(alpha: 0.45),
                  borderStrokeWidth: 1,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                // My-location dot (flutter_map has no built-in one).
                Marker(
                  point: center,
                  width: 22,
                  height: 22,
                  child: const _MyLocationDot(),
                ),
                // Blue: rentable personal items. Node items are not
                // individual markers — they live in their Node's inventory.
                for (final item in items)
                  Marker(
                    point: LatLng(item.lat, item.lng),
                    width: 38,
                    height: 38,
                    alignment: Alignment.topCenter,
                    child: _ItemMarker(
                      onTap: () =>
                          context.push('/items/${item.id}', extra: item),
                    ),
                  ),
                // Gold: Nodes, drawn above items.
                for (final node in nodes)
                  Marker(
                    point: LatLng(node.lat, node.lng),
                    width: 46,
                    height: 46,
                    // Anchor the pin's tip at the coordinate.
                    alignment: Alignment.topCenter,
                    child: _NodeMarker(
                      onTap: () => NodeSheet.show(context, node),
                    ),
                  ),
              ],
            ),
            const SimpleAttributionWidget(
              // OSM tile usage policy requires attribution.
              source: Text('OpenStreetMap contributors'),
              alignment: Alignment.bottomLeft,
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton.small(
            heroTag: 'refresh-map',
            tooltip: 'Refresh the map',
            onPressed: onRefresh,
            child: const Icon(Icons.refresh),
          ),
        ),
        if (loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 3),
          ),
        if (bothEmpty)
          _OverlayCard(
            icon: Icons.explore_off_outlined,
            message: 'Nothing within 5 km yet — list the first item or '
                'register a Node!',
          ),
        if (nodesState is NodesError)
          _OverlayCard(
            icon: Icons.cloud_off_outlined,
            message: nodesState.message,
            actionLabel: 'Retry',
            onAction: onRetryNodes,
          )
        else if (itemsState is ItemsError)
          _OverlayCard(
            icon: Icons.cloud_off_outlined,
            message: itemsState.message,
            actionLabel: 'Retry',
            onAction: onRetryItems,
          ),
      ],
    );
  }
}

/// Compact filter bar for the item layer: category chips + max-rate slider.
class _ItemFilterBar extends StatelessWidget {
  const _ItemFilterBar({
    required this.category,
    required this.maxRate,
    required this.maxRateCeiling,
    required this.onCategoryChanged,
    required this.onMaxRateChanged,
    required this.onMaxRateChangeEnd,
  });

  final String? category;
  final double maxRate;
  final double maxRateCeiling;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<double> onMaxRateChanged;
  final ValueChanged<double> onMaxRateChangeEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final noCap = maxRate >= maxRateCeiling;
    return Material(
      color: scheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: category == null,
                      showCheckmark: false,
                      onSelected: (_) => onCategoryChanged(null),
                    ),
                  ),
                  for (final (value, label) in kItemCategories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: category == value,
                        showCheckmark: false,
                        onSelected: (selected) =>
                            onCategoryChanged(selected ? value : null),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(Icons.payments_outlined,
                    size: 18, color: scheme.onSurfaceVariant),
                Expanded(
                  child: Slider(
                    value: maxRate,
                    min: 100,
                    max: maxRateCeiling,
                    divisions: 49,
                    onChanged: onMaxRateChanged,
                    onChangeEnd: onMaxRateChangeEnd,
                  ),
                ),
                SizedBox(
                  width: 86,
                  child: Text(
                    noCap ? 'Any price' : '≤ PKR ${maxRate.round()}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
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

/// Blue pin for a rentable item, tip anchored at the item's coordinate.
class _ItemMarker extends StatelessWidget {
  const _ItemMarker({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(
        Icons.location_pin,
        size: 36,
        color: kItemBlue,
        shadows: [
          Shadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

/// Gold pin for a Node, tip anchored at the node's coordinate.
class _NodeMarker extends StatelessWidget {
  const _NodeMarker({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(
        Icons.location_pin,
        size: 44,
        color: kNodeGold,
        shadows: [
          Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

/// Classic blue "you are here" dot.
class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6),
        ],
      ),
    );
  }
}

/// Floating card pinned above the bottom edge for empty/error states, so the
/// map stays visible behind it.
class _OverlayCard extends StatelessWidget {
  const _OverlayCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: 16,
      right: 88, // clear of the FAB
      bottom: 24,
      child: Card(
        color: scheme.surface.withValues(alpha: 0.96),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
        ),
      ),
    );
  }
}
