import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../state/auth_store.dart';

/// Pushes login only when the current action needs an account.
/// Returns true if the user is signed in when this completes.
Future<bool> ensureLoggedIn(BuildContext context) async {
  if (AuthStore.instance.isAuthed) return true;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return AuthStore.instance.isAuthed;
}
