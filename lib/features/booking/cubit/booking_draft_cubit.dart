import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/result.dart';
import '../../packages/models/consult_package.dart';
import '../models/booking.dart';
import '../models/consultant.dart';
import '../models/quote.dart';
import '../models/slot.dart';
import '../repo/booking_repository.dart';

class BookingDraftState extends Equatable {
  final ConsultPackage? package;
  final Consultant? consultant;
  final String? date;
  final Slot? slot;
  final Quote? quote;
  final bool quoting;
  final bool submitting;

  const BookingDraftState({
    this.package,
    this.consultant,
    this.date,
    this.slot,
    this.quote,
    this.quoting = false,
    this.submitting = false,
  });

  bool get readyForConfirm =>
      package != null && consultant != null && date != null && slot != null;

  BookingDraftState copyWith({
    ConsultPackage? package,
    Consultant? consultant,
    String? date,
    Slot? slot,
    Quote? quote,
    bool? quoting,
    bool? submitting,
    bool clearConsultant = false,
    bool clearDate = false,
    bool clearSlot = false,
    bool clearQuote = false,
  }) {
    return BookingDraftState(
      package: package ?? this.package,
      consultant: clearConsultant ? null : consultant ?? this.consultant,
      date: clearDate ? null : date ?? this.date,
      slot: clearSlot ? null : slot ?? this.slot,
      quote: clearQuote ? null : quote ?? this.quote,
      quoting: quoting ?? this.quoting,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props =>
      [package, consultant, date, slot, quote, quoting, submitting];
}

class BookingDraftCubit extends Cubit<BookingDraftState> {
  BookingDraftCubit(this._repository) : super(const BookingDraftState());

  final BookingRepository _repository;
  int _quoteGen = 0;

  void reset() {
    _quoteGen++;
    emit(const BookingDraftState());
  }

  void pickPackage(ConsultPackage package) {
    emit(state.copyWith(package: package, clearQuote: true));
    refreshQuote();
  }

  void pickConsultant(Consultant consultant) {
    emit(state.copyWith(
      consultant: consultant,
      clearDate: true,
      clearSlot: true,
      clearQuote: true,
    ));
    refreshQuote();
  }

  void pickDate(String date) {
    emit(state.copyWith(date: date, clearSlot: true, clearQuote: true));
    refreshQuote();
  }

  void pickSlot(Slot slot) {
    emit(state.copyWith(slot: slot));
    refreshQuote();
  }

  Future<void> refreshQuote() async {
    final package = state.package;
    if (package == null) return;
    final gen = ++_quoteGen;
    final consultant = state.consultant;
    final date = state.date;
    final time = state.slot?.time;
    emit(state.copyWith(quoting: true));
    final result = await _repository.quote(
      packageId: package.id,
      consultantId: consultant?.id,
      date: date,
      time: time,
    );
    if (isClosed || gen != _quoteGen) return;
    emit(state.copyWith(
      quoting: false,
      quote: result is Success<Quote> ? result.data : null,
      clearQuote: result is! Success<Quote>,
    ));
  }

  Future<Result<BookingCreateResult>?> submit({
    int? clientLocationId,
    int? paymentMethodId,
    String? cardToken,
    String? notes,
  }) async {
    final package = state.package;
    final consultant = state.consultant;
    final date = state.date;
    final slot = state.slot;
    if (package == null || consultant == null || date == null || slot == null) {
      return null;
    }
    emit(state.copyWith(submitting: true));
    final result = await _repository.createBooking(
      packageId: package.id,
      consultantId: consultant.id,
      date: date,
      time: slot.time,
      clientLocationId: clientLocationId,
      paymentMethodId: paymentMethodId,
      cardToken: cardToken,
      notes: notes,
    );
    if (!isClosed) emit(state.copyWith(submitting: false));
    return result;
  }
}
