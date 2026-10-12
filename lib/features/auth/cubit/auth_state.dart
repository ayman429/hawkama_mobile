import 'package:equatable/equatable.dart';

import '../models/client_user.dart';

class AuthState extends Equatable {
  final bool ready;
  final ClientUser? user;
  final bool submitting;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  const AuthState({
    this.ready = false,
    this.user,
    this.submitting = false,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  bool get isAuthed => user != null;

  AuthState copyWith({
    bool? ready,
    ClientUser? user,
    bool? submitting,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      ready: ready ?? this.ready,
      user: clearUser ? null : user ?? this.user,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      fieldErrors: clearError ? const {} : fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => [ready, user, submitting, errorMessage, fieldErrors];
}
