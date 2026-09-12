part of 'system_playlist_screen.dart';

extension _SystemQueueActions on SystemPlaylistScreenState {
  _ManagementRequest _captureRequest(
    SystemPlaylistContent snapshot,
    SystemPlaylistEntry? entry,
  ) => _ManagementRequest(
    snapshot,
    entry,
    widget.queue?.state,
    entry == null ? null : controller.queueSourcePermit(snapshot, entry),
  );

  bool get _queuePageLive =>
      mounted &&
      _active &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      !MediaQuery.sizeOf(context).isEmpty;

  bool Function() _queuePagePermit() {
    final epoch = _queueEpoch;
    return () => _queuePageLive && epoch == _queueEpoch && _request == null;
  }

  void _queueChanged() {
    final request = _request;
    if (request?.entry != null &&
        !identical(request!.queue, widget.queue?.state)) {
      _dismiss();
    }
  }

  Future<void> _insertEntry(
    _ManagementRequest request, {
    required bool next,
  }) async {
    final queue = widget.queue,
        expected = request.queue,
        entry = request.entry,
        sourcePermit = request.sourcePermit;
    if (!_queuePageLive ||
        !identical(_request, request) ||
        queue == null ||
        expected == null ||
        entry == null ||
        sourcePermit?.call() != true) {
      return;
    }
    final pagePermit = _queuePagePermit();
    final edit = queue.prepareInsertion(expected, entry.reference, next: next);
    _dismiss();
    if (edit == null || !pagePermit()) return;
    _setQueueNotice(null);
    final result = await queue.submitEdit(
      edit,
      canEdit: () => pagePermit() && sourcePermit!(),
    );
    if (!pagePermit() || !sourcePermit!()) return;
    if (result.status == QueueEditStatus.applied ||
        result.status == QueueEditStatus.cancelled) {
      _setQueueNotice(
        result.status == QueueEditStatus.applied
            ? (next ? '已设为下一首播放。当前播放不会中断。' : '已添加到队列末尾。当前播放不会中断。')
            : '队列已变化，请重新打开歌曲菜单再试。',
      );
    }
  }

  Widget? _queueFeedback() {
    final queue = widget.queue;
    if (queue == null || controller.type == SystemPlaylistType.queue) {
      return null;
    }
    final permit = _queuePagePermit(), noticeIdentity = _noticeIdentity;
    return QueueOperationFeedback(
      queue: queue,
      permit: permit,
      notice: _queueNotice,
      onOpenQueue: () =>
          widget.navigation.openSystemPlaylist(SystemPlaylistType.queue),
      onDismissNotice: () {
        if (permit() && identical(noticeIdentity, _noticeIdentity)) {
          _setQueueNotice(null);
        }
      },
    );
  }
}
