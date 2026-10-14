import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/result.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../models/booking.dart';
import '../repo/booking_repository.dart';

enum ListStatus { loading, guest, ready }

class BookingsState extends Equatable {
  final ListStatus status;
  final List<Booking> items;

  const BookingsState({
    this.status = ListStatus.loading,
    this.items = const [],
  });

  @override
  List<Object?> get props => [status, items];
}

class BookingsCubit extends Cubit<BookingsState> {
  BookingsCubit(this._repository, this._auth) : super(const BookingsState()) {
    _authKey = _keyOf(_auth.state);
    _sub = _auth.stream.listen((next) {
      final key = _keyOf(next);
      if (key == _authKey) return;
      _authKey = key;
      load();
    });
  }

  final BookingRepository _repository;
  final AuthCubit _auth;
  late final StreamSubscription<dynamic> _sub;
  late String _authKey;
  int _gen = 0;

  String _keyOf(dynamic state) => '${state.isAuthed}-${state.user?.id}';

  Future<void> load() async {
    final gen = ++_gen;
    if (!_auth.state.isAuthed) {
      emit(const BookingsState(status: ListStatus.guest));
      return;
    }
    if (state.items.isEmpty) {
      emit(const BookingsState(status: ListStatus.loading));
    }
    final result = await _repository.bookings();
    if (isClosed || gen != _gen) return;
    emit(BookingsState(
      status: ListStatus.ready,
      items: result.fold((data) => data, (_) => const []),
    ));
  }

  Future<Failure?> cancel(int id) async {
    final result = await _repository.cancelBooking(id);
    switch (result) {
      case Success():
        await load();
        return null;
      case Err(:final failure):
        return failure;
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
