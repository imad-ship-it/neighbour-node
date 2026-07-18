import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/location_service.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/node_entity.dart';
import '../bloc/node_bloc.dart';
import '../widgets/location_gate_view.dart';
import '../widgets/node_sheet.dart';
import '../widgets/nodes_style.dart';

/// Authenticated home: Google Map centred on the user with a translucent
/// 5 km radius circle and gold markers for nearby active Nodes.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

/// Where the page is in the "can we show the map yet" flow.
enum _Gate { checking, denied, deniedForever, serviceOff, ready }

class _MapPageState extends State<MapPage> {
  static const double _radiusMeters = 5000;

  final LocationService _location = sl<LocationService>();
  late final NodeBloc _nodeBloc = sl<NodeBloc>();

  _Gate _gate = _Gate.checking;
  Position? _position;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _nodeBloc.close();
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

  /// Refresh FAB: re-read the position (it may have changed), re-query.
  Future<void> _refresh() async {
    if (_gate != _Gate.ready) return _bootstrap();
    try {
      final position = await _location.getCurrentPosition();
      if (!mounted) return;
      setState(() => _position = position);
      unawaited(_mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      ));
      unawaited(_location.syncLocationToBackend(position));
    } catch (_) {
      // Keep the previous position; still re-run the query.
    }
    _loadNodes();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _nodeBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nearby Nodes'),
          actions: [
            IconButton(
              tooltip: 'Log out',
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  context.read<AuthBloc>().add(const LogoutRequested()),
            ),
          ],
        ),
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
          _Gate.ready => _MapView(
              position: _position!,
              radiusMeters: _radiusMeters,
              onMapCreated: (controller) => _mapController = controller,
              onRetry: _loadNodes,
            ),
        },
        floatingActionButton: _gate == _Gate.ready
            ? FloatingActionButton(
                tooltip: 'Refresh nearby nodes',
                onPressed: _refresh,
                child: const Icon(Icons.refresh),
              )
            : null,
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({
    required this.position,
    required this.radiusMeters,
    required this.onMapCreated,
    required this.onRetry,
  });

  final Position position;
  final double radiusMeters;
  final void Function(GoogleMapController) onMapCreated;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(position.latitude, position.longitude);
    return BlocBuilder<NodeBloc, NodeState>(
      builder: (context, state) {
        final nodes = state is NodesLoaded ? state.nodes : const <NodeEntity>[];
        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 13),
              onMapCreated: onMapCreated,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              // Leave room for the refresh FAB + overlays.
              padding: const EdgeInsets.only(bottom: 96),
              circles: {
                Circle(
                  circleId: const CircleId('search-radius'),
                  center: center,
                  radius: radiusMeters,
                  fillColor: kNodeGold.withValues(alpha: 0.07),
                  strokeColor: kNodeGold.withValues(alpha: 0.45),
                  strokeWidth: 1,
                ),
              },
              markers: {
                for (final node in nodes)
                  Marker(
                    markerId: MarkerId('node-${node.id}'),
                    position: LatLng(node.lat, node.lng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(kNodeGoldHue),
                    onTap: () => NodeSheet.show(context, node),
                  ),
              },
            ),
            if (state is NodesLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 3),
              ),
            if (state is NodesLoaded && state.nodes.isEmpty)
              _OverlayCard(
                icon: Icons.explore_off_outlined,
                message: 'No Nodes within 5 km yet — maybe yours '
                    'will be the first?',
              ),
            if (state is NodesError)
              _OverlayCard(
                icon: Icons.cloud_off_outlined,
                message: state.message,
                actionLabel: 'Retry',
                onAction: onRetry,
              ),
          ],
        );
      },
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
