import 'package:json_annotation/json_annotation.dart';

import '../../../nodes/data/models/node_detail_model.dart'
    show NodeManagerModel;
import '../../../nodes/data/models/node_model.dart' show NodeLocationModel;
import '../../domain/entities/item_detail_entity.dart';

part 'item_detail_model.g.dart';

/// Mirrors the DRF `ItemDetailSerializer` payload
/// (backend/items/serializers.py).
@JsonSerializable(fieldRename: FieldRename.snake)
class ItemDetailModel {
  const ItemDetailModel({
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
    required this.location,
    required this.images,
    required this.owner,
    this.node,
    this.nodeName,
  });

  factory ItemDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ItemDetailModelFromJson(json);

  final int id;
  final String title;
  @JsonKey(defaultValue: '')
  final String description;
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
  @JsonKey(defaultValue: [])
  final List<ItemImageModel> images;
  final NodeManagerModel owner;
  final int? node;
  final String? nodeName;

  Map<String, dynamic> toJson() => _$ItemDetailModelToJson(this);

  static double _decimalFromJson(dynamic value) =>
      double.tryParse(value.toString()) ?? 0.0;

  ItemDetailEntity toEntity() => ItemDetailEntity(
        id: id,
        title: title,
        description: description,
        category: category,
        condition: condition,
        dailyRate: dailyRate,
        depositAmount: depositAmount,
        storageType: storageType,
        listingStatus: listingStatus,
        isAvailable: isAvailable,
        lat: location.lat,
        lng: location.lng,
        imageUrls: images.map((image) => image.image).toList(),
        owner: owner.toEntity(),
        nodeId: node,
        nodeName: nodeName,
      );
}

@JsonSerializable()
class ItemImageModel {
  const ItemImageModel({
    required this.id,
    required this.image,
    required this.order,
  });

  factory ItemImageModel.fromJson(Map<String, dynamic> json) =>
      _$ItemImageModelFromJson(json);

  final int id;
  final String image;
  final int order;

  Map<String, dynamic> toJson() => _$ItemImageModelToJson(this);
}
