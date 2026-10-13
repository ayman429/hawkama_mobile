import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/result.dart';
import '../models/client_location.dart';
import '../repo/profile_repository.dart';

class AddressesState extends Equatable {
  final bool loading;
  final bool busy;
  final List<ClientLocation> items;
  final String? error;

  const AddressesState({
    this.loading = true,
    this.busy = false,
    this.items = const [],
    this.error,
  });

  AddressesState copyWith({
    bool? loading,
    bool? busy,
    List<ClientLocation>? items,
    String? error,
    bool clearError = false,
  }) {
    return AddressesState(
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      items: items ?? this.items,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [loading, busy, items, error];
}

class AddressesCubit extends Cubit<AddressesState> {
  AddressesCubit(this._repository) : super(const AddressesState());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: state.items.isEmpty, clearError: true));
    final result = await _repository.locations();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(loading: false, items: data, clearError: true));
      case Err(:final failure):
        emit(state.copyWith(loading: false, error: failure.message));
    }
  }

  Future<Failure?> save({
    int? id,
    required String name,
    required String city,
    required String address,
    required bool isDefault,
  }) async {
    emit(state.copyWith(busy: true));
    final result = await _repository.saveLocation(
      id: id,
      name: name,
      city: city,
      address: address,
      isDefault: isDefault,
    );
    if (isClosed) return null;
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

  Future<Failure?> makeDefault(int id) async {
    emit(state.copyWith(busy: true));
    final result = await _repository.setDefaultLocation(id);
    if (isClosed) return null;
    return _after(result);
  }

  Future<Failure?> remove(int id) async {
    emit(state.copyWith(busy: true));
    final result = await _repository.deleteLocation(id);
    if (isClosed) return null;
    return _after(result);
  }

  Future<Failure?> _after(Result<void> result) async {
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
