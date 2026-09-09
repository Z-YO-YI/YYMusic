import '../domain/models/domain_failure.dart';
import '../domain/models/queue_edit.dart';

enum QueueEditStatus { applied, cancelled, busy, failed }

/// A retained failure identity and original intent, never raw dependency text.
final class QueueEditFailure {
  QueueEditFailure(this.edit, DomainFailureCode code)
    : failure = DomainFailure(
        code: code,
        diagnosticId: 'queue.edit-failed',
        retryable: true,
      );
  final QueueEdit edit;
  final DomainFailure failure;
  String get message => '队列操作未完成。请检查当前队列后再试。';
}

/// Per-attempt outcome. Cancellation includes stale snapshots and no-op edits.
final class QueueEditResult {
  const QueueEditResult.applied()
    : status = QueueEditStatus.applied,
      failure = null;
  const QueueEditResult.cancelled()
    : status = QueueEditStatus.cancelled,
      failure = null;
  const QueueEditResult.busy() : status = QueueEditStatus.busy, failure = null;
  const QueueEditResult.failed(QueueEditFailure this.failure)
    : status = QueueEditStatus.failed;
  final QueueEditStatus status;
  final QueueEditFailure? failure;
}
