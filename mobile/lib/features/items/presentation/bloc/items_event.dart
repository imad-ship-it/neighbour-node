part of 'items_bloc.dart';

sealed class ItemsEvent extends Equatable {
  const ItemsEvent();

  @override
  List<Object?> get props => const [];
}

/// Fetch nearby rentable items (map load, refresh, and every filter change).
class LoadNearbyItems extends ItemsEvent {
  const LoadNearbyItems({
    required this.lat,
    required this.lng,
    this.radiusMeters = 5000,
    this.category,
    this.maxRate,
  });

  final double lat;
  final double lng;
  final double radiusMeters;
  final String? category;
  final double? maxRate;

  @override
  List<Object?> get props => [lat, lng, radiusMeters, category, maxRate];
}
