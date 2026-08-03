class AppUser {
  final String id;
  final String name;
  final String email;
  final List<String> preferences;
  final String createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.preferences,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      preferences: (json['preferences'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  AppUser copyWith({List<String>? preferences}) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
    );
  }
}
