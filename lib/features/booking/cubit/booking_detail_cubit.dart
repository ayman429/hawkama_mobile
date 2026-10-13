import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/result.dart';
import '../models/booking.dart';
import '../repo/booking_repository.dart';

class BookingDetailState extends Equatable {
  final bool loading;
  final Booking? booking;
  final String? error;

  const BookingDetailState({
    this.loading = true,
    this.booking,
    this.error,
  });

  @override
  List<Object?> get props => [loading, booking, error];
}

class BookingDetailCubit extends Cubit<BookingDetailState> {
  BookingDetailCubit(this._repository) : super(const BookingDetailState());

  final BookingRepository _repository;

  Future<void> load(int id) async {
    emit(const BookingDetailState());
    final result = await _repository.booking(id);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(BookingDetailState(loading: false, booking: data));
      case Err(:final failure):
        emit(BookingDetailState(loading: false, error: failure.message));
    }
  }
}
