// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NodeDetailModel _$NodeDetailModelFromJson(Map<String, dynamic> json) =>
    NodeDetailModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      location: NodeLocationModel.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      operatingHours: NodeDetailModel._hoursFromJson(
        json['operating_hours'] as Map<String, dynamic>?,
      ),
      capacity: (json['capacity'] as num).toInt(),
      isActive: json['is_active'] as bool,
      rating: NodeDetailModel._ratingFromJson(json['rating']),
      totalTransactions: (json['total_transactions'] as num).toInt(),
      isOpenNow: json['is_open_now'] as bool,
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => NodePhotoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      manager: NodeManagerModel.fromJson(
        json['manager'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$NodeDetailModelToJson(NodeDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'address': instance.address,
      'location': instance.location,
      'operating_hours': instance.operatingHours,
      'capacity': instance.capacity,
      'is_active': instance.isActive,
      'rating': instance.rating,
      'total_transactions': instance.totalTransactions,
      'is_open_now': instance.isOpenNow,
      'photos': instance.photos,
      'manager': instance.manager,
    };

NodePhotoModel _$NodePhotoModelFromJson(Map<String, dynamic> json) =>
    NodePhotoModel(
      id: (json['id'] as num).toInt(),
      image: json['image'] as String,
      order: (json['order'] as num).toInt(),
    );

Map<String, dynamic> _$NodePhotoModelToJson(NodePhotoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'image': instance.image,
      'order': instance.order,
    };

NodeManagerModel _$NodeManagerModelFromJson(Map<String, dynamic> json) =>
    NodeManagerModel(
      id: (json['id'] as num).toInt(),
      displayName: json['display_name'] as String? ?? '',
      rating: NodeDetailModel._ratingFromJson(json['rating']),
      photo: json['photo'] as String?,
    );

Map<String, dynamic> _$NodeManagerModelToJson(NodeManagerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'rating': instance.rating,
      'photo': instance.photo,
    };
