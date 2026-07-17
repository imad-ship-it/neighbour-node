// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  username: json['username'] as String,
  displayName: json['display_name'] as String? ?? '',
  isPhoneVerified: json['is_phone_verified'] as bool,
  role: json['role'] as String,
  rating: UserModel._ratingFromJson(json['rating']),
  totalRentals: (json['total_rentals'] as num).toInt(),
  totalLendings: (json['total_lendings'] as num).toInt(),
  address: json['address'] as String? ?? '',
  isIdVerified: json['is_id_verified'] as bool,
  dateJoined: json['date_joined'] as String,
  phoneNumber: json['phone_number'] as String?,
  photo: json['photo'] as String?,
  location: json['location'] == null
      ? null
      : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
  fcmToken: json['fcm_token'] as String?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'username': instance.username,
  'display_name': instance.displayName,
  'phone_number': instance.phoneNumber,
  'is_phone_verified': instance.isPhoneVerified,
  'photo': instance.photo,
  'role': instance.role,
  'rating': instance.rating,
  'total_rentals': instance.totalRentals,
  'total_lendings': instance.totalLendings,
  'location': instance.location,
  'address': instance.address,
  'fcm_token': instance.fcmToken,
  'is_id_verified': instance.isIdVerified,
  'date_joined': instance.dateJoined,
};

LocationModel _$LocationModelFromJson(Map<String, dynamic> json) =>
    LocationModel(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );

Map<String, dynamic> _$LocationModelToJson(LocationModel instance) =>
    <String, dynamic>{'lat': instance.lat, 'lng': instance.lng};
