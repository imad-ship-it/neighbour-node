import 'package:equatable/equatable.dart';

/// Full node payload from GET /nodes/{id}/ — everything the detail page and
/// the post-registration screens need. Pure Dart (CLAUDE.md dependency rule).
class NodeDetailEntity extends Equatable {
  const NodeDetailEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.lat,
    required this.lng,
    required this.operatingHours,
    required this.capacity,
    required this.isActive,
    required this.rating,
    required this.totalTransactions,
    required this.isOpenNow,
    required this.photoUrls,
    required this.manager,
  });

  final int id;
  final String name;
  final String description;
  final String address;
  final double lat;
  final double lng;

  /// `{"mon": "09:00-18:00", ..., "sun": "closed"}` — same shape the backend
  /// stores (MASTER_PLAN §4.2).
  final Map<String, String> operatingHours;
  final int capacity;
  final bool isActive;
  final double rating;
  final int totalTransactions;
  final bool isOpenNow;
  final List<String> photoUrls;
  final NodeManagerEntity manager;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        address,
        lat,
        lng,
        operatingHours,
        capacity,
        isActive,
        rating,
        totalTransactions,
        isOpenNow,
        photoUrls,
        manager,
      ];
}

/// Public subset of the manager's profile shown on the detail page.
class NodeManagerEntity extends Equatable {
  const NodeManagerEntity({
    required this.id,
    required this.displayName,
    required this.rating,
    this.photoUrl,
  });

  final int id;
  final String displayName;
  final double rating;
  final String? photoUrl;

  @override
  List<Object?> get props => [id, displayName, rating, photoUrl];
}
