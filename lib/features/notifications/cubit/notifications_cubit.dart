import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../models/client_notif.dart';
import '../repo/notifications_repository.dart';

enum ListStatus { loading, guest, ready }

class NotificationsState extends Equatable {
  final ListStatus status;
  final List<ClientNotif> items;

  const NotificationsState({
    this.status = ListStatus.loading,
    this.items = const [],
  });

  bool get hasUnread => items.any((item) => item.unread);

  @override
  List<Object?> get props => [status, items];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository, this._auth)
      : super(const NotificationsState()) {
    _authKey = '${_auth.state.isAuthed}-${_auth.state.user?.id}';
    _sub = _auth.stream.listen((next) {
      final key = '${next.isAuthed}-${next.user?.id}';
      if (key == _authKey) return;
      _authKey = key;
      load();
    });
    load();
  }

  final NotificationsRepository _repository;
  final AuthCubit _auth;
  late final StreamSubscription<dynamic> _sub;
  late String _authKey;

  Future<void> load() async {
    if (!_auth.state.isAuthed) {
      emit(const NotificationsState(status: ListStatus.guest));
      return;
    }
    final result = await _repository.notifications();
    if (isClosed) return;
    emit(NotificationsState(
      status: ListStatus.ready,
      items: result.fold((data) => data, (_) => const []),
    ));
  }

  Future<void> markAllRead() async {
    await _repository.markAllRead();
    if (isClosed) return;
    emit(NotificationsState(
      status: state.status,
      items: [for (final item in state.items) item.copyWith(unread: false)],
    ));
  }

  void markRead(String id) {
    _repository.markRead(id);
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
