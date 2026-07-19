import 'package:equatable/equatable.dart';

/// Domain representation of an item as returned by the list endpoints
/// (nearby / my / node inventory). Pure Dart (CLAUDE.md dependency rule).
class ItemEntity extends Equatable {
  const ItemEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.condition,
    required this.dailyRate,
    required this.depositAmount,
    required this.storageType,
    required this.listingStatus,
    required this.isAvailable,
    required this.lat,
    required this.lng,
    this.nodeId,
    this.distanceMeters,
    this.thumbnailUrl,
  });

  final int id;
  final String title;

  /// TOOLS | BOOKS | ELECTRONICS | SPORTS | OTHER (§4.3).
  final String category;

  /// NEW | GOOD | FAIR | POOR.
  final String condition;
  final double dailyRate;
  final double depositAmount;

  /// PERSONAL | NODE.
  final String storageType;

  /// PENDING_DONATION | ACTIVE | REJECTED | ARCHIVED.
  final String listingStatus;
  final bool isAvailable;
  final double lat;
  final double lng;
  final int? nodeId;
  final double? distanceMeters;
  final String? thumbnailUrl;

  bool get isPersonal => storageType == 'PERSONAL';
  bool get isPendingDonation => listingStatus == 'PENDING_DONATION';
  bool get isActive => listingStatus == 'ACTIVE';
  bool get isRejected => listingStatus == 'REJECTED';

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        condition,
        dailyRate,
        depositAmount,
        storageType,
        listingStatus,
        isAvailable,
        lat,
        lng,
        nodeId,
        distanceMeters,
        thumbnailUrl,
      ];
}
