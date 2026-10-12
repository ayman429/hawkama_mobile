import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../models/consult_package.dart';
import '../models/subscription.dart';
import '../repo/packages_repository.dart';

class PackagesState extends Equatable {
  final List<ConsultPackage>? packages;
  final List<Subscription> subscriptions;

  const PackagesState({this.packages, this.subscriptions = const []});

  @override
  List<Object?> get props => [packages, subscriptions];
}

class PackagesCubit extends Cubit<PackagesState> {
  PackagesCubit(this._repository, this._auth) : super(const PackagesState()) {
    load();
  }

  final PackagesRepository _repository;
  final AuthCubit _auth;

  Future<void> load() async {
    final packages = await _repository.packages();
    final subscriptions = _auth.state.isAuthed
        ? await _repository.activeSubscriptions()
        : null;
    if (isClosed) return;
    emit(PackagesState(
      packages: packages.fold((data) => data, (_) => const []),
      subscriptions: subscriptions?.fold((data) => data, (_) => const []) ??
          const [],
    ));
  }
}
