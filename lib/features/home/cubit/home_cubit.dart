import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../notifications/repo/notifications_repository.dart';
import '../../packages/models/consult_package.dart';
import '../../packages/repo/packages_repository.dart';
import '../models/dashboard.dart';
import '../repo/home_repository.dart';

class HomeState extends Equatable {
  final bool loading;
  final Dashboard? dashboard;
  final List<ConsultPackage> services;
  final int unread;

  const HomeState({
    this.loading = true,
    this.dashboard,
    this.services = const [],
    this.unread = 0,
  });

  HomeState copyWith({
    bool? loading,
    Dashboard? dashboard,
    List<ConsultPackage>? services,
    int? unread,
    bool clearDashboard = false,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      dashboard: clearDashboard ? null : dashboard ?? this.dashboard,
      services: services ?? this.services,
      unread: unread ?? this.unread,
    );
  }

  @override
  List<Object?> get props => [loading, dashboard, services, unread];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._home,
    this._packages,
    this._notifications,
    this._auth,
  ) : super(const HomeState()) {
    _authKey = '${_auth.state.isAuthed}-${_auth.state.user?.id}';
    _sub = _auth.stream.listen((next) {
      final key = '${next.isAuthed}-${next.user?.id}';
      if (key == _authKey) return;
      _authKey = key;
      load();
    });
    load();
  }

  final HomeRepository _home;
  final PackagesRepository _packages;
  final NotificationsRepository _notifications;
  final AuthCubit _auth;
  late final StreamSubscription<dynamic> _sub;
  late String _authKey;
  int _gen = 0;

  Future<void> load() async {
    final gen = ++_gen;
    final authed = _auth.state.isAuthed;
    if (authed && state.dashboard == null && !state.loading) {
      emit(state.copyWith(loading: true));
    }
    try {
      final dashboardFuture = authed ? _home.dashboard() : null;
      final servicesFuture = _packages.packages();
      final unreadFuture = authed ? _notifications.unreadCount() : null;
      final dashboard = await dashboardFuture;
      final services = await servicesFuture;
      final unread = await unreadFuture;
      if (isClosed || gen != _gen) return;
      emit(HomeState(
        loading: false,
        dashboard: dashboard?.fold((data) => data, (_) => null),
        services: services.fold((data) => data, (_) => const []),
        unread: unread?.fold((data) => data, (_) => 0) ?? 0,
      ));
    } catch (_) {
      if (!isClosed && gen == _gen) {
        emit(state.copyWith(loading: false));
      }
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
