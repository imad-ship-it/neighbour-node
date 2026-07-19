// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemModel _$ItemModelFromJson(Map<String, dynamic> json) => ItemModel(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  category: json['category'] as String,
  condition: json['condition'] as String,
  dailyRate: ItemModel._decimalFromJson(json['daily_rate']),
  depositAmount: ItemModel._decimalFromJson(json['deposit_amount']),
  storageType: json['storage_type'] as String,
  listingStatus: json['listing_status'] as String,
  isAvailable: json['is_available'] as bool,
  location: NodeLocationModel.fromJson(
    json['location'] as Map<String, dynamic>,
  ),
  node: (json['node'] as num?)?.toInt(),
  distance: (json['distance'] as num?)?.toDouble(),
  thumbnail: json['thumbnail'] as String?,
);

Map<String, dynamic> _$ItemModelToJson(ItemModel instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'category': instance.category,
  'condition': instance.condition,
  'daily_rate': instance.dailyRate,
  'deposit_amount': instance.depositAmount,
  'storage_type': instance.storageType,
  'listing_status': instance.listingStatus,
  'is_available': instance.isAvailable,
  'location': instance.location,
  'node': instance.node,
  'distance': instance.distance,
  'thumbnail': instance.thumbnail,
};
