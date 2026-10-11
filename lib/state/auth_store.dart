import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/repo.dart';

/// Client auth state. Token lives in SecureStorage (never plain prefs),
/// mirroring `client_token` in the guide §2.2. Guest mode = no token.
class AuthStore extends ChangeNotifier {
  AuthStore._() {
    // Any 401 from the API clears the session (guide §1.4 UNAUTHENTICATED).
    ApiClient.onUnauthorized = signOut;
  }

  static final AuthStore instance = AuthStore._();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'client_token';

  ClientUser? user;
  bool _ready = false;
  bool get ready => _ready;
  bool get isAuthed => AuthTokenHolder.token != null;

  Future<void> init() async {
    AuthTokenHolder.token = await _storage.read(key: _tokenKey);
    if (AuthTokenHolder.token != null) {
      try {
        user = await Repo.me();
      } catch (_) {
        user = null; // stale/expired token — stays guest until next login
      }
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final r = await Repo.login(email, password);
    await _apply(r);
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String company,
    required String password,
    required String passwordConfirmation,
  }) async {
    final r = await Repo.register(
      name: name,
      email: email,
      phone: phone,
      company: company,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    await _apply(r);
  }

  Future<void> _apply(AuthResult r) async {
    AuthTokenHolder.token = r.token;
    user = r.user;
    await _storage.write(key: _tokenKey, value: r.token);
    notifyListeners();
  }

  Future<void> signOut() async {
    await Repo.logout();
    AuthTokenHolder.token = null;
    user = null;
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }
}
