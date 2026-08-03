import '../models/itinerary.dart';
import 'api_client.dart';

class ItineraryService {
  final ApiClient _client;

  ItineraryService(this._client);

  Future<List<Itinerary>> list(String token) async {
    final data = await _client.get('/itineraries', token: token);
    return (data['itineraries'] as List<dynamic>)
        .map((e) => Itinerary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Itinerary> create(
    String token, {
    required String title,
    String? startDate,
    String? endDate,
    String? notes,
    required List<Map<String, String>> items,
  }) async {
    final data = await _client.post('/itineraries', token: token, body: {
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'notes': notes ?? '',
      'items': items,
    });
    return Itinerary.fromJson(data['itinerary']);
  }

  Future<void> remove(String token, String id) async {
    await _client.delete('/itineraries/$id', token: token);
  }
}
