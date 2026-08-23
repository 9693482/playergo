class Team {
  final String id;
  final String userId;
  final String teamName;
  final String? logoUrl;
  final String? sportId;
  final String? description;
  final String? captainName;
  final String? captainPhone;
  final double rating;
  final int completedMatches;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Team({
    required this.id,
    required this.userId,
    required this.teamName,
    this.logoUrl,
    this.sportId,
    this.description,
    this.captainName,
    this.captainPhone,
    this.rating = 0,
    this.completedMatches = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      teamName: json['team_name'] as String,
      logoUrl: json['logo_url'] as String?,
      sportId: json['sport_id'] as String?,
      description: json['description'] as String?,
      captainName: json['captain_name'] as String?,
      captainPhone: json['captain_phone'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      completedMatches: json['completed_matches'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_name': teamName,
      'logo_url': logoUrl,
      'sport_id': sportId,
      'description': description,
      'captain_name': captainName,
      'captain_phone': captainPhone,
    };
  }
}
