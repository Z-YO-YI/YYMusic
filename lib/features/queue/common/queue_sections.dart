part of 'queue_screen.dart';

extension _QueueSections on QueueScreenState {
  List<Widget> _slivers() {
    final read = controller.read, data = controller.read.content;
    final permit = controller.permit();
    final editable = data != null && controller.canEdit(data);
    final root = controller.expected, failure = widget.queue.editFailure;
    Widget box(Widget child) => SliverToBoxAdapter(
      child: Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
    );
    VoidCallback action(VoidCallback callback) => () {
      if (_interactive && permit()) callback();
    };
    return [
      box(
        Row(
          children: [
            YYButton(
              label: '返回',
              focusNode: _backFocus,
              onPressed: action(widget.navigation.back),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('播放队列', style: YYTypography.pageTitle)),
            YYIconButton(
              glyph: YYGlyph.refresh,
              label: '刷新队列',
              onPressed: action(read.refresh),
            ),
          ],
        ),
      ),
      box(
        Text(
          data != null && data.entries.length > 1
              ? widget.platform == YYPlatform.windows
                    ? '拖动手柄排序，也可使用上下移按钮'
                    : '长按拖动，或用上下移调整顺序'
              : '调整播放顺序或移除歌曲',
          style: YYTypography.caption,
        ),
      ),
      box(
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '共 ${data?.totalCount ?? root.entries.length} 首',
              style: YYTypography.caption,
            ),
            YYButton(
              label: '清空',
              glyph: YYGlyph.trash,
              onPressed: editable && root.entries.isNotEmpty
                  ? () =>
                        _edit(QueueEdit.clear(root), permit, confirmClear: true)
                  : null,
            ),
          ],
        ),
      ),
      if (widget.queue.editBusy || read.busy) box(const Text('正在处理队列操作…')),
      if (failure != null)
        box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              YYErrorBanner(
                title: '队列操作未完成',
                message: '${failure.message}\n重试移除当前项或清空仍会停止播放。',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  YYButton(
                    label: '重试队列操作',
                    onPressed: editable && widget.queue.canRetryEdit(failure)
                        ? action(
                            () => unawaited(
                              widget.queue.retryEdit(
                                failure,
                                canEdit: () => _interactive && permit(),
                              ),
                            ),
                          )
                        : null,
                  ),
                  YYButton(
                    label: '知道了',
                    onPressed: action(
                      () => widget.queue.dismissEditFailure(failure),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      if (read.actionError != null)
        box(YYErrorBanner(title: '播放未完成', message: read.actionError!)),
      if (read.phase == LoadPhase.error)
        box(
          YYErrorBanner(
            title: '无法读取队列',
            message: '请检查存储后重试。',
            actionLabel: '重试读取',
            onAction: action(read.refresh),
          ),
        )
      else if (read.loading)
        box(const Text('正在读取队列…'))
      else if (data != null && !controller.matches(data))
        box(
          YYErrorBanner(
            title: '队列正在同步',
            message: '显示内容与当前队列不一致，请刷新后操作。',
            actionLabel: '刷新队列内容',
            onAction: action(read.refresh),
          ),
        )
      else if (data?.entries.isEmpty == true)
        box(
          const YYEmptyState(
            glyph: YYGlyph.queue,
            message: '播放队列为空。\n可从音乐库播放歌曲或添加队列条目。',
          ),
        ),
      if (data != null && data.entries.isNotEmpty) ...[
        box(
          Text(
            '第 ${data.page.offset + 1}–${data.page.offset + data.entries.length} 条 / 共 ${data.totalCount} 条',
            style: YYTypography.caption,
          ),
        ),
        QueueReorderSliver(
          key: ValueKey((data, root, controller.interactionRevision)),
          count: data.entries.length,
          enabled: editable && _interactive,
          platform: widget.platform,
          itemBuilder: (_, index) => _row(data, index, editable, permit),
          begin: (index) =>
              controller.beginDrag(data, index, () => _interactive && permit()),
          onMove: (drag, edit) {
            if (_interactive && drag.permit()) {
              unawaited(
                controller.submit(edit, () => _interactive && drag.permit()),
              );
            }
          },
        ),
        box(
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (data.page.offset > 0)
                YYButton(
                  label: '上一组',
                  onPressed: read.canShowPreviousWindow
                      ? action(() => read.showPreviousWindow(data))
                      : null,
                ),
              if (data.hasMore)
                YYButton(
                  label: read.capped ? '下一组' : '更多歌曲',
                  onPressed: read.canShowNextWindow
                      ? action(() => read.showNextWindow(data))
                      : read.canLoadMore
                      ? action(() => read.loadMore(data))
                      : null,
                ),
            ],
          ),
        ),
        box(Text('不可用的歌曲仍可排序和移除，不会删除音乐文件。', style: YYTypography.caption)),
      ],
    ];
  }

  Widget _row(
    SystemPlaylistContent data,
    int index,
    bool editable,
    bool Function() permit,
  ) {
    final entry = data.entries[index], track = data.entries[index].track;
    final root = controller.expected, id = entry.entryId!;
    final current = id == root.currentEntryId;
    FocusNode focus(YYGlyph glyph) => _actionFocus.putIfAbsent((
      id,
      glyph,
    ), () => FocusNode(debugLabel: 'queue ${glyph.assetName}'));
    final upFocus = focus(YYGlyph.up),
        downFocus = focus(YYGlyph.down),
        removeFocus = focus(YYGlyph.close);
    final valid =
        editable &&
        entry.position < root.entries.length &&
        root.entries[entry.position].id == id;
    return YYQueueTile(
      key: ValueKey(('queue-row', id)),
      title: track?.title ?? '未解析的歌曲',
      meta:
          '${current ? '当前项 · ' : ''}${SystemPlaylistSections.availabilityLabel(entry)} · ${track?.artists.join(' / ') ?? '保留来源引用'}',
      durationLabel: track == null
          ? '—'
          : '${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
      artwork: YYArtworkKind.local,
      current: current,
      allowManagementWhenDisabled: valid,
      alwaysShowActions: widget.platform == YYPlatform.android,
      moveUpFocusNode: upFocus,
      moveDownFocusNode: downFocus,
      removeFocusNode: removeFocus,
      onPressed: valid && controller.read.canPlayEntry(data, entry.identity)
          ? () {
              if (_interactive && permit()) {
                unawaited(controller.read.playEntry(data, entry.identity));
              }
            }
          : null,
      onMoveUp: valid && entry.position > 0
          ? () => _edit(
              QueueEdit.move(
                root,
                id,
                beforeEntryId: root.entries[entry.position - 1].id,
              ),
              permit,
              restoreFocus: upFocus,
            )
          : null,
      onMoveDown: valid && entry.position < root.entries.length - 1
          ? () => _edit(
              QueueEdit.move(
                root,
                id,
                beforeEntryId: entry.position + 2 < root.entries.length
                    ? root.entries[entry.position + 2].id
                    : null,
              ),
              permit,
              restoreFocus: downFocus,
            )
          : null,
      onRemove: valid
          ? () => _edit(
              QueueEdit.remove(root, id),
              permit,
              confirmClear: current ? false : null,
            )
          : null,
    );
  }
}
