// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemDetailModel _$ItemDetailModelFromJson(Map<String, dynamic> json) =>
    ItemDetailModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String,
      condition: json['condition'] as String,
      dailyRate: ItemDetailModel._decimalFromJson(json['daily_rate']),
      depositAmount: ItemDetailModel._decimalFromJson(json['deposit_amount']),
      storageType: json['storage_type'] as String,
      listingStatus: json['listing_status'] as String,
      isAvailable: json['is_available'] as bool,
      location: NodeLocationModel.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => ItemImageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      owner: NodeManagerModel.fromJson(json['owner'] as Map<String, dynamic>),
      node: (json['node'] as num?)?.toInt(),
      nodeName: json['node_name'] as String?,
    );

Map<String, dynamic> _$ItemDetailModelToJson(ItemDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'condition': instance.condition,
      'daily_rate': instance.dailyRate,
      'deposit_amount': instance.depositAmount,
      'storage_type': instance.storageType,
      'listing_status': instance.listingStatus,
      'is_available': instance.isAvailable,
      'location': instance.location,
      'images': instance.images,
      'owner': instance.owner,
      'node': instance.node,
      'node_name': instance.nodeName,
    };

ItemImageModel _$ItemImageModelFromJson(Map<String, dynamic> json) =>
    ItemImageModel(
      id: (json['id'] as num).toInt(),
      image: json['image'] as String,
      order: (json['order'] as num).toInt(),
    );

Map<String, dynamic> _$ItemImageModelToJson(ItemImageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'image': instance.image,
      'order': instance.order,
    };
