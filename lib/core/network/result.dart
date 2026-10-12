import 'failure.dart';

sealed class Result<T> {
  const Result();

  R fold<R>(
    R Function(T data) onSuccess,
    R Function(Failure failure) onFailure,
  );
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(Failure failure) onFailure,
  ) =>
      onSuccess(data);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);

  @override
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(Failure failure) onFailure,
  ) =>
      onFailure(failure);
}

Future<Result<T>> guard<T>(Future<T> Function() action) async {
  try {
    return Success(await action());
  } catch (error) {
    return Err(Failure.from(error));
  }
}
