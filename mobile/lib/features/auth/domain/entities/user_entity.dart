import 'package:equatable/equatable.dart';

/// Domain representation of the signed-in user. Pure Dart — no JSON, no
/// Flutter, no backend knowledge (CLAUDE.md dependency rule).
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.rating,
    required this.isPhoneVerified,
    this.photoUrl,
  });

  final int id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role;
  final double rating;
  final bool isPhoneVerified;

  bool get isNodeManager => role == 'NODE_MANAGER';

  @override
  List<Object?> get props =>
      [id, email, displayName, photoUrl, role, rating, isPhoneVerified];
}
