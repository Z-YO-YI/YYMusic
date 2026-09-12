part of 'playlist_content_screen.dart';

extension _PlaylistQueueActions on PlaylistContentScreenState {
  _MenuRequest _captureMenu(String id, PlaylistContent snapshot) {
    final entry = snapshot.entries.firstWhere((item) => item.entry.id == id);
    return _MenuRequest(
      id,
      snapshot,
      widget.queue?.state,
      controller.queueSourcePermit(snapshot, entry),
    );
  }

  bool get _queuePageLive =>
      mounted &&
      _active &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      !MediaQuery.sizeOf(context).isEmpty;

  bool Function() _queuePagePermit() {
    final epoch = _queueEpoch;
    return () => _queuePageLive && epoch == _queueEpoch && _menu == null;
  }

  void _queueChanged() {
    final request = _menu;
    if (request != null && !identical(request.queue, widget.queue?.state)) {
      _dismiss();
    }
  }

  Future<void> _insertEntry(_MenuRequest request, {required bool next}) async {
    final queue = widget.queue,
        expected = request.queue,
        sourcePermit = request.sourcePermit;
    if (!_queuePageLive ||
        !identical(_menu, request) ||
        queue == null ||
        expected == null ||
        sourcePermit?.call() != true) {
      return;
    }
    final entry = request.snapshot.entries.firstWhere(
      (item) => item.entry.id == request.id,
    );
    final pagePermit = _queuePagePermit();
    final edit = queue.prepareInsertion(
      expected,
      entry.entry.track,
      next: next,
    );
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
    if (queue == null) return null;
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
