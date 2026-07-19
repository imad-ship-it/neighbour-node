import 'package:json_annotation/json_annotation.dart';

// Same `{"lat": ..., "lng": ...}` payload as nodes — reused like the backend
// reuses its location serialization across apps.
import '../../../nodes/data/models/node_model.dart' show NodeLocationModel;
import '../../domain/entities/item_entity.dart';

part 'item_model.g.dart';

/// Mirrors the DRF `ItemListSerializer` payload (backend/items/serializers.py).
/// The detail payload is a superset, so this model parses both.
@JsonSerializable(fieldRename: FieldRename.snake)
class ItemModel {
  const ItemModel({
    required this.id,
    required this.title,
    required this.category,
    required this.condition,
    required this.dailyRate,
    required this.depositAmount,
    required this.storageType,
    required this.listingStatus,
    required this.isAvailable,
    required this.location,
    this.node,
    this.distance,
    this.thumbnail,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) =>
      _$ItemModelFromJson(json);

  final int id;
  final String title;
  final String category;
  final String condition;
  @JsonKey(fromJson: _decimalFromJson)
  final double dailyRate;
  @JsonKey(fromJson: _decimalFromJson)
  final double depositAmount;
  final String storageType;
  final String listingStatus;
  final bool isAvailable;
  final NodeLocationModel location;
  final int? node;
  final double? distance;
  final String? thumbnail;

  Map<String, dynamic> toJson() => _$ItemModelToJson(this);

  /// DRF DecimalField arrives as `"500.00"`.
  static double _decimalFromJson(dynamic value) =>
      double.tryParse(value.toString()) ?? 0.0;

  ItemEntity toEntity() => ItemEntity(
        id: id,
        title: title,
        category: category,
        condition: condition,
        dailyRate: dailyRate,
        depositAmount: depositAmount,
        storageType: storageType,
        listingStatus: listingStatus,
        isAvailable: isAvailable,
        lat: location.lat,
        lng: location.lng,
        nodeId: node,
        distanceMeters: distance,
        thumbnailUrl: thumbnail,
      );
}
