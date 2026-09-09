part of 'queue_controller.dart';

extension on QueueController {
  Future<QueueEditResult> _submitEdit(
    QueueEdit request, {
    bool Function()? canEdit,
    QueueEditFailure? retrying,
  }) {
    if (_disposed) return Future.value(const QueueEditResult.cancelled());
    if (_editBusy) return Future.value(const QueueEditResult.busy());
    if (!identical(state, request.expected)) {
      return Future.value(const QueueEditResult.cancelled());
    }
    final done = Completer<QueueEditResult>();
    // Register before notifying listeners: even a reentrant close must drain.
    _editWork = done.future.then<void>((_) {});
    _editBusy = true;
    unawaited(
      Future<void>.microtask(() async {
        var result = const QueueEditResult.cancelled();
        try {
          final applied = await edit(request, canEdit: canEdit);
          if (applied) {
            result = const QueueEditResult.applied();
            if (retrying != null && identical(_editFailure, retrying)) {
              _editFailure = null;
            }
          }
        } catch (error) {
          final failure = QueueEditFailure(
            request,
            error is DomainFailure ? error.code : DomainFailureCode.unknown,
          );
          _editFailure = failure;
          result = QueueEditResult.failed(failure);
        } finally {
          _editBusy = false;
          done.complete(result);
          _forwardChange();
        }
      }),
    );
    _forwardChange();
    return done.future;
  }
}
