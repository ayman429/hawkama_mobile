import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/failure.dart';
import '../repo/support_repository.dart';

class SupportState extends Equatable {
  final bool sending;
  const SupportState({this.sending = false});

  @override
  List<Object?> get props => [sending];
}

class SupportCubit extends Cubit<SupportState> {
  SupportCubit(this._repository) : super(const SupportState());

  final SupportRepository _repository;

  Future<Failure?> send(String subject, String message) async {
    emit(const SupportState(sending: true));
    final result = await _repository.send(subject, message);
    if (!isClosed) emit(const SupportState());
    return result.fold((_) => null, (failure) => failure);
  }
}
