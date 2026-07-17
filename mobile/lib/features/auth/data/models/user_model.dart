import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

/// Mirrors the DRF `UserSerializer` payload (backend/accounts/serializers.py)
/// exactly — snake_case keys, decimal `rating` serialized as a string.
@JsonSerializable(fieldRename: FieldRename.snake)
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.isPhoneVerified,
    required this.role,
    required this.rating,
    required this.totalRentals,
    required this.totalLendings,
    required this.address,
    required this.isIdVerified,
    required this.dateJoined,
    this.phoneNumber,
    this.photo,
    this.location,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  final int id;
  final String email;
  final String username;
  @JsonKey(defaultValue: '')
  final String displayName;
  final String? phoneNumber;
  final bool isPhoneVerified;
  final String? photo;
  final String role;
  @JsonKey(fromJson: _ratingFromJson)
  final double rating;
  final int totalRentals;
  final int totalLendings;
  final LocationModel? location;
  @JsonKey(defaultValue: '')
  final String address;
  final String? fcmToken;
  final bool isIdVerified;
  final String dateJoined;

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// DRF DecimalField arrives as `"0.00"`.
  static double _ratingFromJson(dynamic value) =>
      double.tryParse(value.toString()) ?? 0.0;

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        displayName: displayName.isNotEmpty ? displayName : email,
        photoUrl: photo,
        role: role,
        rating: rating,
        isPhoneVerified: isPhoneVerified,
      );
}

/// `location` object in the /me payload: `{"lat": ..., "lng": ...}`.
@JsonSerializable()
class LocationModel {
  const LocationModel({required this.lat, required this.lng});

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);

  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => _$LocationModelToJson(this);
}
