class Position {
  final String id;
  final String sportId;
  final String name;
  final String slug;
  final bool isActive;

  const Position({
    required this.id,
    required this.sportId,
    required this.name,
    required this.slug,
    this.isActive = true,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as String,
      sportId: json['sport_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sport_id': sportId,
      'name': name,
      'slug': slug,
      'is_active': isActive,
    };
  }
}
