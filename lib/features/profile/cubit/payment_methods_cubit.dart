import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/result.dart';
import '../models/saved_card.dart';
import '../repo/profile_repository.dart';

class PaymentMethodsState extends Equatable {
  final bool loading;
  final bool busy;
  final List<SavedCard> items;
  final String? error;

  const PaymentMethodsState({
    this.loading = true,
    this.busy = false,
    this.items = const [],
    this.error,
  });

  PaymentMethodsState copyWith({
    bool? loading,
    bool? busy,
    List<SavedCard>? items,
    String? error,
    bool clearError = false,
  }) {
    return PaymentMethodsState(
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      items: items ?? this.items,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [loading, busy, items, error];
}

class PaymentMethodsCubit extends Cubit<PaymentMethodsState> {
  PaymentMethodsCubit(this._repository) : super(const PaymentMethodsState());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: state.items.isEmpty, clearError: true));
    final result = await _repository.paymentMethods();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(loading: false, items: data, clearError: true));
      case Err(:final failure):
        emit(state.copyWith(loading: false, error: failure.message));
    }
  }

  Future<Failure?> save({required String token, required bool isDefault}) async {
    emit(state.copyWith(busy: true));
    final result = await _repository.saveCard(token: token, isDefault: isDefault);
    if (isClosed) return null;
    return _after(result);
  }

  Future<Failure?> makeDefault(int id) async {
    emit(state.copyWith(busy: true));
    final result = await _repository.setDefaultCard(id);
    if (isClosed) return null;
    return _after(result);
  }

  Future<Failure?> remove(int id) async {
    emit(state.copyWith(busy: true));
    final result = await _repository.deleteCard(id);
    if (isClosed) return null;
    return _after(result);
  }

  Future<Failure?> _after<T>(Result<T> result) async {
    switch (result) {
      case Success():
        await load();
        if (!isClosed) emit(state.copyWith(busy: false));
        return null;
      case Err(:final failure):
        emit(state.copyWith(busy: false));
        return failure;
    }
  }
}
