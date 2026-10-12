import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../models/client_report.dart';
import '../repo/reports_repository.dart';

enum ListStatus { loading, guest, ready }

class ReportsState extends Equatable {
  final ListStatus status;
  final List<ClientReport> items;

  const ReportsState({
    this.status = ListStatus.loading,
    this.items = const [],
  });

  @override
  List<Object?> get props => [status, items];
}

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this._repository, this._auth) : super(const ReportsState()) {
    _authKey = '${_auth.state.isAuthed}-${_auth.state.user?.id}';
    _sub = _auth.stream.listen((next) {
      final key = '${next.isAuthed}-${next.user?.id}';
      if (key == _authKey) return;
      _authKey = key;
      load();
    });
    load();
  }

  final ReportsRepository _repository;
  final AuthCubit _auth;
  late final StreamSubscription<dynamic> _sub;
  late String _authKey;
  int _gen = 0;

  Future<void> load() async {
    final gen = ++_gen;
    if (!_auth.state.isAuthed) {
      emit(const ReportsState(status: ListStatus.guest));
      return;
    }
    final result = await _repository.reports();
    if (isClosed || gen != _gen) return;
    emit(ReportsState(
      status: ListStatus.ready,
      items: result.fold((data) => data, (_) => const []),
    ));
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
