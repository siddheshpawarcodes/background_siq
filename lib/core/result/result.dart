import '../errors/failures.dart';

/// Lightweight functional result type used across all layers (SRS §13.1).
///
/// Avoids throwing across architectural boundaries: use cases and repositories
/// return [Result] so callers must handle both paths explicitly.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// Returns the value or `null` when this is an [Err].
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  /// Returns the failure or `null` when this is an [Ok].
  Failure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final failure) => failure,
      };

  /// Folds both branches into a single value.
  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final failure) => onErr(failure),
      };

  /// Transforms the success value, preserving failures.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T>(:final value) => Ok<R>(transform(value)),
        Err<T>(:final failure) => Err<R>(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
