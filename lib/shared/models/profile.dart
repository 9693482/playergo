import 'enums/enums.dart';

class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final UserRole role;
  final String? photoUrl;
  final VerificationStatus verificationStatus;
  final String? countryId;
  final String? regionId;
  final String? cityId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    this.role = UserRole.player,
    this.photoUrl,
    this.verificationStatus = VerificationStatus.unverified,
    this.countryId,
    this.regionId,
    this.cityId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: _parseRole(json['role'] as String?),
      photoUrl: json['photo_url'] as String?,
      verificationStatus: _parseVerification(json['verification_status'] as String?),
      countryId: json['country_id'] as String?,
      regionId: json['region_id'] as String?,
      cityId: json['city_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role.name,
      'photo_url': photoUrl,
      'verification_status': verificationStatus.name,
      'country_id': countryId,
      'region_id': regionId,
      'city_id': cityId,
      'is_active': isActive,
    };
  }

  static UserRole _parseRole(String? value) {
    switch (value) {
      case 'PLAYER':
        return UserRole.player;
      case 'TEAM':
        return UserRole.team;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.player;
    }
  }

  static VerificationStatus _parseVerification(String? value) {
    switch (value) {
      case 'UNVERIFIED':
        return VerificationStatus.unverified;
      case 'PENDING':
        return VerificationStatus.pending;
      case 'VERIFIED':
        return VerificationStatus.verified;
      case 'REJECTED':
        return VerificationStatus.rejected;
      case 'SUSPENDED':
        return VerificationStatus.suspended;
      default:
        return VerificationStatus.unverified;
    }
  }

  Profile copyWith({
    String? fullName,
    String? phone,
    UserRole? role,
    String? photoUrl,
    String? countryId,
    String? regionId,
    String? cityId,
  }) {
    return Profile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      verificationStatus: verificationStatus,
      countryId: countryId ?? this.countryId,
      regionId: regionId ?? this.regionId,
      cityId: cityId ?? this.cityId,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
