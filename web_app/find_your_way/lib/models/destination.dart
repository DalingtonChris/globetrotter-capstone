class Destination {
  final String id;
  final String name;
  final String category;
  final String city;
  final String country;
  final String description;
  final List<String> tags;
  final double rating;
  final int priceLevel;
  final String? image;
  final int popularity;

  const Destination({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.country,
    required this.description,
    required this.tags,
    required this.rating,
    required this.priceLevel,
    required this.image,
    required this.popularity,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      priceLevel: (json['priceLevel'] as num?)?.toInt() ?? 1,
      image: json['image'] as String?,
      popularity: (json['popularity'] as num?)?.toInt() ?? 0,
    );
  }

  String get priceLabel => '₣' * priceLevel;
  String get location => [city, country].where((s) => s.isNotEmpty).join(', ');
}
