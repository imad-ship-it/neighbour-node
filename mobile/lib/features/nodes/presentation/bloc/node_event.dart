part of 'node_bloc.dart';

sealed class NodeEvent extends Equatable {
  const NodeEvent();

  @override
  List<Object?> get props => const [];
}

/// Fetch active nodes around the point (map load + every refresh).
class LoadNearbyNodes extends NodeEvent {
  const LoadNearbyNodes({
    required this.lat,
    required this.lng,
    this.radiusMeters = 5000,
  });

  final double lat;
  final double lng;
  final double radiusMeters;

  @override
  List<Object?> get props => [lat, lng, radiusMeters];
}
