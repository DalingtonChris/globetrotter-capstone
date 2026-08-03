import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Thin JSON/REST wrapper around [http.Client] shared by all services.
class ApiClient {
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> get(String path, {String? token, Map<String, String>? query}) async {
    final uri = Uri.parse('$apiBaseUrl$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v)),
    );
    final response = await _client.get(uri, headers: _headers(token));
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, String? token}) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final response = await _client.post(uri, headers: _headers(token), body: jsonEncode(body ?? {}));
    return _decode(response);
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body, String? token}) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final response = await _client.put(uri, headers: _headers(token), body: jsonEncode(body ?? {}));
    return _decode(response);
  }

  Future<void> delete(String path, {String? token}) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final response = await _client.delete(uri, headers: _headers(token));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _decode(response);
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) data = decoded;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data['error'] as String? ?? 'Something went wrong. Please try again.';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
