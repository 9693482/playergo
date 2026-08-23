class Player {
  final String id;
  final String userId;
  final String sportId;
  final String positionId;
  final String? bio;
  final int experienceYears;
  final double pricePerMatch;
  final double rating;
  final int completedMatches;
  final bool availabilityStatus;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Player({
    required this.id,
    required this.userId,
    required this.sportId,
    required this.positionId,
    this.bio,
    this.experienceYears = 0,
    required this.pricePerMatch,
    this.rating = 0,
    this.completedMatches = 0,
    this.availabilityStatus = true,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sportId: json['sport_id'] as String,
      positionId: json['position_id'] as String,
      bio: json['bio'] as String?,
      experienceYears: json['experience_years'] as int? ?? 0,
      pricePerMatch: (json['price_per_match'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      completedMatches: json['completed_matches'] as int? ?? 0,
      availabilityStatus: json['availability_status'] as bool? ?? true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'sport_id': sportId,
      'position_id': positionId,
      'bio': bio,
      'experience_years': experienceYears,
      'price_per_match': pricePerMatch,
      'availability_status': availabilityStatus,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
