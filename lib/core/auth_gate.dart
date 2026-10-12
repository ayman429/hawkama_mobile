import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import '../features/auth/cubit/auth_cubit.dart';

Future<bool> ensureLoggedIn(BuildContext context) async {
  if (context.read<AuthCubit>().state.isAuthed) return true;
  await context.push(AppRoutes.login);
  if (!context.mounted) return false;
  return context.read<AuthCubit>().state.isAuthed;
}
