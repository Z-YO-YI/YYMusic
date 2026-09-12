part of 'catalog_detail_screen.dart';

extension _CatalogQueueActions on CatalogDetailScreenState {
  Future<void> _pickPlaylist(Track track) async {
    if (_pickerOpen || !controller.canOpenActions(track.ref)) return;
    final focus = _returnFocus;
    _dismiss(restoreFocus: false);
    _pickerOpen = true;
    _queueEpoch++;
    _queueActive = false;
    controller.setActive(false);
    try {
      await widget.navigation.addToPlaylist(track.ref, title: track.title);
    } finally {
      if (mounted) {
        _pickerOpen = false;
        final active =
            TickerMode.valuesOf(context).enabled &&
            (ModalRoute.of(context)?.isCurrent ?? true) &&
            !MediaQuery.sizeOf(context).isEmpty;
        _queueActive = active;
        _queueEpoch++;
        controller.setActive(active);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_queuePageLive && _menuTrack == null && focus?.context != null) {
            focus!.requestFocus();
          }
        });
      }
    }
  }

  bool get _queuePageLive =>
      mounted &&
      _queueActive &&
      !_pickerOpen &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      !MediaQuery.sizeOf(context).isEmpty;

  bool Function() _queuePagePermit() {
    final epoch = _queueEpoch;
    return () => _queuePageLive && epoch == _queueEpoch && _menuTrack == null;
  }

  void _queueChanged() {
    if (_menuQueue != null && !identical(_menuQueue, widget.queue?.state)) {
      _dismiss();
    }
  }

  Future<void> _insertTrack(Track track, {required bool next}) async {
    final queue = widget.queue,
        expected = _menuQueue,
        sourcePermit = _menuSourcePermit;
    if (!_queuePageLive ||
        _tab != CatalogDetailTab.tracks ||
        queue == null ||
        expected == null ||
        sourcePermit?.call() != true) {
      return;
    }
    final pagePermit = _queuePagePermit();
    final edit = queue.prepareInsertion(expected, track.ref, next: next);
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
