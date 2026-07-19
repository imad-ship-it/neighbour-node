import 'package:equatable/equatable.dart';

import '../../../nodes/domain/entities/node_detail_entity.dart'
    show NodeManagerEntity;

/// Full item payload from GET /items/{id}/ — everything the detail page
/// needs. Reuses [NodeManagerEntity] as the generic public-profile shape.
class ItemDetailEntity extends Equatable {
  const ItemDetailEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.dailyRate,
    required this.depositAmount,
    required this.storageType,
    required this.listingStatus,
    required this.isAvailable,
    required this.lat,
    required this.lng,
    required this.imageUrls,
    required this.owner,
    this.nodeId,
    this.nodeName,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String condition;
  final double dailyRate;
  final double depositAmount;
  final String storageType;
  final String listingStatus;
  final bool isAvailable;
  final double lat;
  final double lng;
  final List<String> imageUrls;
  final NodeManagerEntity owner;
  final int? nodeId;
  final String? nodeName;

  bool get isActive => listingStatus == 'ACTIVE';
  bool get isRentable => isActive && isAvailable;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        condition,
        dailyRate,
        depositAmount,
        storageType,
        listingStatus,
        isAvailable,
        lat,
        lng,
        imageUrls,
        owner,
        nodeId,
        nodeName,
      ];
}
