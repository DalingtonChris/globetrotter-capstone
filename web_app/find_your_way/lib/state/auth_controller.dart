import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

const _tokenKey = 'fyw_token';

/// App-wide auth state: current token/user plus login, register, logout.
///
/// Kept deliberately small for Phase 1 — the monolith API is the source of
/// truth, this controller just mirrors session state for the UI and persists
/// the JWT across reloads via [SharedPreferences].
class AuthController extends ChangeNotifier {
  final AuthService _authService;

  AuthController(ApiClient client) : _authService = AuthService(client);

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  String? token;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);

    if (savedToken == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final fetchedUser = await _authService.me(savedToken);
      token = savedToken;
      user = fetchedUser;
      status = AuthStatus.authenticated;
    } catch (_) {
      await prefs.remove(_tokenKey);
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final result = await _authService.login(email: email, password: password);
    await _persistSession(result);
  }

  Future<void> register({required String name, required String email, required String password}) async {
    final result = await _authService.register(name: name, email: email, password: password);
    await _persistSession(result);
  }

  Future<void> updatePreferences(List<String> preferences) async {
    if (token == null) return;
    final updated = await _authService.updatePreferences(token!, preferences);
    user = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    token = null;
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _persistSession(AuthResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, result.token);
    token = result.token;
    user = result.user;
    status = AuthStatus.authenticated;
    notifyListeners();
  }
}
