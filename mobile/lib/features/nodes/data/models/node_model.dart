import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/node_entity.dart';

part 'node_model.g.dart';

/// Mirrors the DRF `NodeListSerializer` payload (backend/nodes/serializers.py)
/// exactly — snake_case keys, decimal `rating` serialized as a string,
/// `distance` in meters, `location` as `{"lat": ..., "lng": ...}`.
@JsonSerializable(fieldRename: FieldRename.snake)
class NodeModel {
  const NodeModel({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.rating,
    required this.isOpenNow,
    this.distance,
    this.thumbnail,
  });

  factory NodeModel.fromJson(Map<String, dynamic> json) =>
      _$NodeModelFromJson(json);

  final int id;
  final String name;
  @JsonKey(defaultValue: '')
  final String address;
  final NodeLocationModel location;
  @JsonKey(fromJson: _ratingFromJson)
  final double rating;
  final bool isOpenNow;
  final double? distance;
  final String? thumbnail;

  Map<String, dynamic> toJson() => _$NodeModelToJson(this);

  /// DRF DecimalField arrives as `"0.00"`.
  static double _ratingFromJson(dynamic value) =>
      double.tryParse(value.toString()) ?? 0.0;

  NodeEntity toEntity() => NodeEntity(
        id: id,
        name: name,
        address: address,
        lat: location.lat,
        lng: location.lng,
        rating: rating,
        isOpenNow: isOpenNow,
        distanceMeters: distance,
        thumbnailUrl: thumbnail,
      );
}

@JsonSerializable()
class NodeLocationModel {
  const NodeLocationModel({required this.lat, required this.lng});

  factory NodeLocationModel.fromJson(Map<String, dynamic> json) =>
      _$NodeLocationModelFromJson(json);

  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => _$NodeLocationModelToJson(this);
}
