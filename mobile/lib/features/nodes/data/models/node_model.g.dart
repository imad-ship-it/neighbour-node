// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NodeModel _$NodeModelFromJson(Map<String, dynamic> json) => NodeModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  address: json['address'] as String? ?? '',
  location: NodeLocationModel.fromJson(
    json['location'] as Map<String, dynamic>,
  ),
  rating: NodeModel._ratingFromJson(json['rating']),
  isOpenNow: json['is_open_now'] as bool,
  distance: (json['distance'] as num?)?.toDouble(),
  thumbnail: json['thumbnail'] as String?,
);

Map<String, dynamic> _$NodeModelToJson(NodeModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'location': instance.location,
  'rating': instance.rating,
  'is_open_now': instance.isOpenNow,
  'distance': instance.distance,
  'thumbnail': instance.thumbnail,
};

NodeLocationModel _$NodeLocationModelFromJson(Map<String, dynamic> json) =>
    NodeLocationModel(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );

Map<String, dynamic> _$NodeLocationModelToJson(NodeLocationModel instance) =>
    <String, dynamic>{'lat': instance.lat, 'lng': instance.lng};
