import '../models/destination.dart';
import 'api_client.dart';

class DestinationService {
  final ApiClient _client;

  DestinationService(this._client);

  Future<List<Destination>> search({String? query, String? category}) async {
    final data = await _client.get('/destinations', query: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (category != null && category != 'All') 'category': category,
    });
    return (data['destinations'] as List<dynamic>)
        .map((e) => Destination.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> categories() async {
    final data = await _client.get('/destinations/categories');
    return (data['categories'] as List<dynamic>).map((e) => e.toString()).toList();
  }

  Future<Destination> getById(String id) async {
    final data = await _client.get('/destinations/$id');
    return Destination.fromJson(data['destination']);
  }

  Future<List<Destination>> recommendations({String? token, int limit = 6}) async {
    final data = await _client.get(
      '/recommendations',
      token: token,
      query: {'limit': '$limit'},
    );
    return (data['destinations'] as List<dynamic>)
        .map((e) => Destination.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
