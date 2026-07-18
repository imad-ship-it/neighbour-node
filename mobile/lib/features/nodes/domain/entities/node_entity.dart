import 'package:equatable/equatable.dart';

/// Domain representation of a community Node as returned by the nearby query.
/// Pure Dart — no JSON, no Flutter (CLAUDE.md dependency rule).
class NodeEntity extends Equatable {
  const NodeEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.isOpenNow,
    this.distanceMeters,
    this.thumbnailUrl,
  });

  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double rating;
  final bool isOpenNow;

  /// Distance from the query point; null outside nearby queries.
  final double? distanceMeters;
  final String? thumbnailUrl;

  @override
  List<Object?> get props =>
      [id, name, address, lat, lng, rating, isOpenNow, distanceMeters, thumbnailUrl];
}
