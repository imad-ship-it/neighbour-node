import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/node_detail_entity.dart';
import 'node_model.dart';

part 'node_detail_model.g.dart';

/// Mirrors the DRF `NodeDetailSerializer` payload
/// (backend/nodes/serializers.py) exactly.
@JsonSerializable(fieldRename: FieldRename.snake)
class NodeDetailModel {
  const NodeDetailModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.location,
    required this.operatingHours,
    required this.capacity,
    required this.isActive,
    required this.rating,
    required this.totalTransactions,
    required this.isOpenNow,
    required this.photos,
    required this.manager,
  });

  factory NodeDetailModel.fromJson(Map<String, dynamic> json) =>
      _$NodeDetailModelFromJson(json);

  final int id;
  final String name;
  @JsonKey(defaultValue: '')
  final String description;
  @JsonKey(defaultValue: '')
  final String address;
  final NodeLocationModel location;
  @JsonKey(fromJson: _hoursFromJson)
  final Map<String, String> operatingHours;
  final int capacity;
  final bool isActive;
  @JsonKey(fromJson: _ratingFromJson)
  final double rating;
  final int totalTransactions;
  final bool isOpenNow;
  @JsonKey(defaultValue: [])
  final List<NodePhotoModel> photos;
  final NodeManagerModel manager;

  Map<String, dynamic> toJson() => _$NodeDetailModelToJson(this);

  /// DRF DecimalField arrives as `"0.00"`.
  static double _ratingFromJson(dynamic value) =>
      double.tryParse(value.toString()) ?? 0.0;

  static Map<String, String> _hoursFromJson(Map<String, dynamic>? json) =>
      (json ?? const {}).map((day, hours) => MapEntry(day, hours.toString()));

  NodeDetailEntity toEntity() => NodeDetailEntity(
        id: id,
        name: name,
        description: description,
        address: address,
        lat: location.lat,
        lng: location.lng,
        operatingHours: operatingHours,
        capacity: capacity,
        isActive: isActive,
        rating: rating,
        totalTransactions: totalTransactions,
        isOpenNow: isOpenNow,
        photoUrls: photos.map((photo) => photo.image).toList(),
        manager: manager.toEntity(),
      );
}

@JsonSerializable()
class NodePhotoModel {
  const NodePhotoModel({
    required this.id,
    required this.image,
    required this.order,
  });

  factory NodePhotoModel.fromJson(Map<String, dynamic> json) =>
      _$NodePhotoModelFromJson(json);

  final int id;
  final String image;
  final int order;

  Map<String, dynamic> toJson() => _$NodePhotoModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class NodeManagerModel {
  const NodeManagerModel({
    required this.id,
    required this.displayName,
    required this.rating,
    this.photo,
  });

  factory NodeManagerModel.fromJson(Map<String, dynamic> json) =>
      _$NodeManagerModelFromJson(json);

  final int id;
  @JsonKey(defaultValue: '')
  final String displayName;
  @JsonKey(fromJson: NodeDetailModel._ratingFromJson)
  final double rating;
  final String? photo;

  Map<String, dynamic> toJson() => _$NodeManagerModelToJson(this);

  NodeManagerEntity toEntity() => NodeManagerEntity(
        id: id,
        displayName: displayName,
        rating: rating,
        photoUrl: photo,
      );
}
