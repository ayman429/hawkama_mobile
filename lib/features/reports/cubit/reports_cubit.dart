import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/result.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../models/client_report.dart';
import '../repo/reports_repository.dart';

enum ListStatus { loading, guest, ready }

class ReportsState extends Equatable {
  final ListStatus status;
  final List<ClientReport> items;

  /// Report id → download progress 0..1 while a download is running.
  final Map<int, double> progress;

  /// Reports whose current version is already on the device.
  final Set<int> saved;

  const ReportsState({
    this.status = ListStatus.loading,
    this.items = const [],
    this.progress = const {},
    this.saved = const {},
  });

  ReportsState copyWith({
    ListStatus? status,
    List<ClientReport>? items,
    Map<int, double>? progress,
    Set<int>? saved,
  }) {
    return ReportsState(
      status: status ?? this.status,
      items: items ?? this.items,
      progress: progress ?? this.progress,
      saved: saved ?? this.saved,
    );
  }

  @override
  List<Object?> get props => [status, items, progress, saved];
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
  }

  final ReportsRepository _repository;
  final AuthCubit _auth;
  late final StreamSubscription<dynamic> _sub;
  late String _authKey;
  int _gen = 0;

  bool get awaitingFirstLoad => state.status == ListStatus.loading;

  Future<void> load() async {
    final gen = ++_gen;
    if (!_auth.state.isAuthed) {
      emit(const ReportsState(status: ListStatus.guest));
      return;
    }
    if (state.status != ListStatus.ready) {
      emit(const ReportsState(status: ListStatus.loading));
    }
    final result = await _repository.reports();
    if (isClosed || gen != _gen) return;
    final items = result.fold((data) => data, (_) => const <ClientReport>[]);
    final saved = <int>{};
    for (final report in items) {
      if (report.available && await _repository.cached(report) != null) {
        saved.add(report.id);
      }
    }
    if (isClosed || gen != _gen) return;
    emit(state.copyWith(status: ListStatus.ready, items: items, saved: saved));
  }

  /// Returns the local file, downloading it first when needed.
  Future<Result<File>> open(ClientReport report) async {
    if (state.progress.containsKey(report.id)) {
      return const Err(Failure(message: '', code: 'BUSY'));
    }
    _setProgress(report.id, 0);
    final result = await _repository.fetch(
      report,
      onProgress: (value) => _setProgress(report.id, value),
    );
    if (isClosed) return result;
    final progress = Map<int, double>.from(state.progress)..remove(report.id);
    switch (result) {
      case Success():
        final items = [
          for (final item in state.items)
            item.id == report.id && item.unread
                ? ClientReport(
                    id: item.id,
                    title: item.title,
                    meta: item.meta,
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt,
                    fileName: item.fileName,
                    mimeType: item.mimeType,
                    available: item.available,
                  )
                : item,
        ];
        emit(state.copyWith(
          items: items,
          progress: progress,
          saved: {...state.saved, report.id},
        ));
      case Err():
        emit(state.copyWith(progress: progress));
    }
    return result;
  }

  void _setProgress(int id, double value) {
    if (isClosed) return;
    emit(state.copyWith(
      progress: {...state.progress, id: value.clamp(0, 1).toDouble()},
    ));
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
