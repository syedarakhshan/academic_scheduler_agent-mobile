import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Replaces the web app's localStorage.getItem('juw_token') /
/// localStorage.getItem('juw_user') with encrypted device storage.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'juw_token';
  static const _userKey = 'juw_user';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveUserJson(String userJson) => _storage.write(key: _userKey, value: userJson);
  Future<String?> getUserJson() => _storage.read(key: _userKey);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
