import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/failure.dart';
import '../../../core/network/result.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/models/client_user.dart';
import '../repo/profile_repository.dart';

class PersonalDataState extends Equatable {
  final bool loading;
  final bool savingProfile;
  final bool savingPassword;
  final ClientUser? profile;
  final String? error;

  const PersonalDataState({
    this.loading = true,
    this.savingProfile = false,
    this.savingPassword = false,
    this.profile,
    this.error,
  });

  PersonalDataState copyWith({
    bool? loading,
    bool? savingProfile,
    bool? savingPassword,
    ClientUser? profile,
    String? error,
    bool clearError = false,
  }) {
    return PersonalDataState(
      loading: loading ?? this.loading,
      savingProfile: savingProfile ?? this.savingProfile,
      savingPassword: savingPassword ?? this.savingPassword,
      profile: profile ?? this.profile,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props =>
      [loading, savingProfile, savingPassword, profile, error];
}

class PersonalDataCubit extends Cubit<PersonalDataState> {
  PersonalDataCubit(this._repository, this._auth)
      : super(const PersonalDataState());

  final ProfileRepository _repository;
  final AuthCubit _auth;

  Future<void> load() async {
    emit(state.copyWith(loading: state.profile == null, clearError: true));
    final result = await _repository.profile();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(loading: false, profile: data, clearError: true));
      case Err(:final failure):
        emit(state.copyWith(loading: false, error: failure.message));
    }
  }

  Future<Failure?> save({
    required String name,
    required String email,
    required String phone,
    required String company,
  }) async {
    emit(state.copyWith(savingProfile: true));
    final result = await _repository.updateProfile(
      name: name,
      email: email,
      phone: phone,
      company: company,
    );
    if (isClosed) return null;
    switch (result) {
      case Success(:final data):
        _auth.applyUser(data);
        emit(state.copyWith(savingProfile: false, profile: data));
        return null;
      case Err(:final failure):
        emit(state.copyWith(savingProfile: false));
        return failure;
    }
  }

  Future<Failure?> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    emit(state.copyWith(savingPassword: true));
    final result = await _repository.updatePassword(
      currentPassword: currentPassword,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    if (isClosed) return null;
    emit(state.copyWith(savingPassword: false));
    return result.fold((_) => null, (failure) => failure);
  }
}
