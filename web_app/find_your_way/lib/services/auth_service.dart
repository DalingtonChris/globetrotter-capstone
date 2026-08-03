import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final String token;
  final AppUser user;

  AuthResult({required this.token, required this.user});
}

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<AuthResult> register({required String name, required String email, required String password}) async {
    final data = await _client.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
    return AuthResult(token: data['token'] as String, user: AppUser.fromJson(data['user']));
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final data = await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return AuthResult(token: data['token'] as String, user: AppUser.fromJson(data['user']));
  }

  Future<AppUser> me(String token) async {
    final data = await _client.get('/auth/me', token: token);
    return AppUser.fromJson(data['user']);
  }

  Future<AppUser> updatePreferences(String token, List<String> preferences) async {
    final data = await _client.put('/auth/preferences', token: token, body: {'preferences': preferences});
    return AppUser.fromJson(data['user']);
  }
}
