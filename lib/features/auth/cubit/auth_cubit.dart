import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../models/client_user.dart';
import '../repo/auth_repository.dart';
import 'auth_state.dart';

export 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository, this._storage) : super(const AuthState());

  final AuthRepository _repository;
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'client_token';
  bool _signingOut = false;

  Future<void> restore() async {
    final token = await _storage.read(key: _tokenKey);
    AuthTokenHolder.token = token;
    if (token != null) {
      final result = await _repository.me();
      final user = result.fold<ClientUser?>((value) => value, (_) => null);
      if (user != null) {
        emit(AuthState(ready: true, user: user));
        return;
      }
      AuthTokenHolder.token = null;
      await _storage.delete(key: _tokenKey);
    }
    emit(const AuthState(ready: true));
  }

  Future<bool> login(String email, String password) async {
    emit(state.copyWith(submitting: true, clearError: true));
    final result = await _repository.login(email, password);
    return result.fold(_apply, _fail);
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String company,
    required String password,
    required String passwordConfirmation,
  }) async {
    emit(state.copyWith(submitting: true, clearError: true));
    final result = await _repository.register(
      name: name,
      email: email,
      phone: phone,
      company: company,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    return result.fold(_apply, _fail);
  }

  Future<bool> _apply(AuthResult result) async {
    AuthTokenHolder.token = result.token;
    await _storage.write(key: _tokenKey, value: result.token);
    emit(AuthState(ready: true, user: result.user));
    return true;
  }

  bool _fail(Failure failure) {
    emit(state.copyWith(
      submitting: false,
      errorMessage: failure.message,
      fieldErrors: failure.firstFieldErrors,
    ));
    return false;
  }

  void clearFeedback() {
    if (state.errorMessage == null && state.fieldErrors.isEmpty) return;
    emit(state.copyWith(clearError: true));
  }

  void applyUser(ClientUser user) {
    if (!state.isAuthed || isClosed) return;
    emit(state.copyWith(ready: true, user: user));
  }

  Future<void> refreshProfile() async {
    if (!state.isAuthed) return;
    final result = await _repository.me();
    if (isClosed) return;
    result.fold(
      (user) => emit(state.copyWith(ready: true, user: user)),
      (_) {},
    );
  }

  Future<void> signOut() async {
    if (_signingOut) return;
    _signingOut = true;
    try {
      if (AuthTokenHolder.token != null) await _repository.logout();
    } finally {
      AuthTokenHolder.token = null;
      await _storage.delete(key: _tokenKey);
      _signingOut = false;
      emit(const AuthState(ready: true));
    }
  }
}
