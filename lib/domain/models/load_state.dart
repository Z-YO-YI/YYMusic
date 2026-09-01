import 'domain_failure.dart';

enum LoadPhase { idle, loading, data, empty, error }

/// Explicit async state for Controllers; repositories remain UI-independent.
final class LoadState<T> {
  const LoadState._({required this.phase, this.data, this.failure});

  const LoadState.idle() : this._(phase: LoadPhase.idle);
  const LoadState.loading() : this._(phase: LoadPhase.loading);
  const LoadState.empty() : this._(phase: LoadPhase.empty);

  factory LoadState.data(T data) =>
      LoadState._(phase: LoadPhase.data, data: data);

  factory LoadState.error(DomainFailure failure) =>
      LoadState._(phase: LoadPhase.error, failure: failure);

  final LoadPhase phase;
  final T? data;
  final DomainFailure? failure;

  bool get isTerminal =>
      phase == LoadPhase.data ||
      phase == LoadPhase.empty ||
      phase == LoadPhase.error;
}
