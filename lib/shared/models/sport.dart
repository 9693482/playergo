class Sport {
  final String id;
  final String name;
  final String slug;
  final bool isActive;

  const Sport({
    required this.id,
    required this.name,
    required this.slug,
    this.isActive = true,
  });

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'is_active': isActive,
    };
  }
}
