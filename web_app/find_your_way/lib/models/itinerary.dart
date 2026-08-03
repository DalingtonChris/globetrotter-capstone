import 'destination.dart';

class ItineraryItem {
  final String destinationId;
  final String note;
  final Destination? destination;

  const ItineraryItem({
    required this.destinationId,
    required this.note,
    required this.destination,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    final destJson = json['destination'] as Map<String, dynamic>?;
    return ItineraryItem(
      destinationId: json['destinationId'] as String,
      note: json['note'] as String? ?? '',
      destination: destJson == null ? null : Destination.fromJson(destJson),
    );
  }
}

class Itinerary {
  final String id;
  final String title;
  final String? startDate;
  final String? endDate;
  final String notes;
  final List<ItineraryItem> items;
  final String createdAt;

  const Itinerary({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.notes,
    required this.items,
    required this.createdAt,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] as String,
      title: json['title'] as String,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      notes: json['notes'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
