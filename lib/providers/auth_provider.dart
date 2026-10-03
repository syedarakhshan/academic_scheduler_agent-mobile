import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/token_storage.dart';
import '../models/user.dart';

/// Mirrors frontend/src/context/AuthContext.js, adapted to Provider.
///
/// Web app                              -> Flutter equivalent
/// ---------------------------------------------------------------
/// localStorage 'juw_token' / 'juw_user' -> TokenStorage (secure storage)
/// useState(user) / loading              -> ChangeNotifier fields + notifyListeners
/// api.defaults.headers.common[...]      -> handled per-request in ApiClient interceptor
/// login()/logout()                      -> same methods, same endpoint contract
class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = true;
  String? _error;

  AppUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// Call once at app startup (e.g. in main.dart) — equivalent of the
  /// AuthProvider's useEffect that restores the session from localStorage.
  Future<void> restoreSession() async {
    ApiClient.instance.onUnauthorized = _handleUnauthorized;

    final token = await TokenStorage.instance.getToken();
    final userJson = await TokenStorage.instance.getUserJson();

    if (token != null && userJson != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        await TokenStorage.instance.clear();
        _user = null;
      }
    }
    _loading = false;
    notifyListeners();
  }

  /// POST /api/auth/login — same contract as AuthContext.js's login().
  Future<AppUser> login(String juwId, String password) async {
    _error = null;
    try {
      final res = await ApiClient.instance.dio.post('/auth/login', data: {
        'juw_id': juwId,
        'password': password,
      });
      print('LOGIN RESPONSE (for diagnosis): status=${res.statusCode} type=${res.data.runtimeType} body=${res.data}');
      final token = res.data['token'] as String;
      final userJson = res.data['user'] as Map<String, dynamic>;

      await TokenStorage.instance.saveToken(token);
      await TokenStorage.instance.saveUserJson(jsonEncode(userJson));

      _user = AppUser.fromJson(userJson);
      notifyListeners();
      return _user!;
    } catch (e) {
      print('LOGIN ERROR (for diagnosis): $e');
      _error = ApiClient.messageFrom(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await TokenStorage.instance.clear();
    _user = null;
    notifyListeners();
  }

  void _handleUnauthorized() {
    _user = null;
    notifyListeners();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await ApiClient.instance.dio.post('/auth/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}
