import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../packages/models/consult_package.dart';
import '../../packages/repo/packages_repository.dart';
import '../models/consultant.dart';
import '../models/slot.dart';
import '../repo/booking_repository.dart';

class WizardPackagesCubit extends Cubit<List<ConsultPackage>?> {
  WizardPackagesCubit(this._repository) : super(null) {
    load();
  }

  final PackagesRepository _repository;

  Future<void> load() async {
    final result = await _repository.packages();
    if (isClosed) return;
    emit(result.fold((data) => data, (_) => const []));
  }
}

class ConsultantsCubit extends Cubit<List<Consultant>?> {
  ConsultantsCubit(this._repository) : super(null) {
    load();
  }

  final BookingRepository _repository;

  Future<void> load() async {
    final result = await _repository.consultants();
    if (isClosed) return;
    emit(result.fold((data) => data, (_) => const []));
  }
}

class ScheduleState extends Equatable {
  final DateTime month;
  final List<String> dates;
  final List<Slot>? slots;
  final bool loadingSlots;

  const ScheduleState({
    required this.month,
    this.dates = const [],
    this.slots,
    this.loadingSlots = false,
  });

  ScheduleState copyWith({
    DateTime? month,
    List<String>? dates,
    List<Slot>? slots,
    bool? loadingSlots,
    bool clearSlots = false,
  }) {
    return ScheduleState(
      month: month ?? this.month,
      dates: dates ?? this.dates,
      slots: clearSlots ? null : slots ?? this.slots,
      loadingSlots: loadingSlots ?? this.loadingSlots,
    );
  }

  @override
  List<Object?> get props => [month, dates, slots, loadingSlots];
}

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(this._repository)
      : super(ScheduleState(
          month: DateTime(DateTime.now().year, DateTime.now().month),
        ));

  final BookingRepository _repository;

  Future<void> loadMonth(int consultantId) async {
    final result = await _repository.availableDates(
      consultantId,
      '${state.month.year}-${state.month.month.toString().padLeft(2, '0')}',
    );
    if (isClosed) return;
    emit(state.copyWith(
      dates: result.fold((data) => data, (_) => const []),
    ));
  }

  Future<void> changeMonth(int consultantId, int delta) async {
    final next = DateTime(state.month.year, state.month.month + delta);
    emit(state.copyWith(month: next, dates: const []));
    await loadMonth(consultantId);
  }

  Future<void> loadSlots(int consultantId, String date) async {
    emit(state.copyWith(loadingSlots: true, clearSlots: true));
    final result = await _repository.slots(consultantId, date);
    if (isClosed) return;
    emit(state.copyWith(
      loadingSlots: false,
      slots: result.fold((data) => data, (_) => const []),
    ));
  }
}
