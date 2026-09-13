part of 'queue_screen.dart';

extension _QueuePlaybackFeedback on QueueScreenState {
  Widget _playbackFeedback(bool Function() permit) {
    final records = widget.queue.playbackFailures;
    VoidCallback action(VoidCallback callback) => () {
      if (_interactive &&
          permit() &&
          identical(records, widget.queue.playbackFailures)) {
        callback();
      }
    };
    return Column(
      key: const ValueKey('queue-playback-feedback'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YYErrorBanner(
          title: '队列中有无法播放的曲目',
          message:
              '本次启动最近 ${records.length} 条记录（最多20条）。失效曲目仍保留在队列中；若全部无法播放，推进会停止。',
        ),
        const SizedBox(height: YYSpace.sm),
        Wrap(
          spacing: YYSpace.md,
          runSpacing: YYSpace.sm,
          children: [
            YYButton(
              key: const ValueKey('queue-playback-details'),
              label: _showPlaybackFailures ? '收起记录' : '查看记录',
              onPressed: action(_togglePlaybackFailures),
            ),
            YYButton(
              key: const ValueKey('queue-playback-acknowledge'),
              label: '知道了',
              onPressed: action(
                () => widget.queue.acknowledgePlaybackFailures(records),
              ),
            ),
          ],
        ),
        if (_showPlaybackFailures)
          for (final record in records.reversed)
            Padding(
              padding: const EdgeInsets.only(top: YYSpace.md),
              child: Text(
                _recordMessage(record),
                style: YYTypography.caption.copyWith(height: 1.6),
              ),
            ),
      ],
    );
  }

  String _recordMessage(QueuePlaybackFailure record) {
    final entry = widget.queue.state.entries
        .where(
          (entry) => entry.id == record.entryId && entry.track == record.track,
        )
        .firstOrNull;
    final data = controller.read.isCurrent ? controller.read.content : null;
    final track = data?.entries
        .where(
          (entry) =>
              entry.entryId == record.entryId &&
              entry.reference == record.track,
        )
        .firstOrNull
        ?.track;
    final title =
        track?.title ??
        (entry == null ? '已移出队列的曲目' : '队列第 ${entry.position + 1} 项');
    final source = record.track.sourceType == MusicSourceType.local
        ? '本地来源'
        : '在线来源';
    final reason = switch (record.code) {
      DomainFailureCode.localFileMissing => '本地文件已失效，请重新定位或扫描。',
      DomainFailureCode.unsupportedAudioFormat => '音频格式暂不支持。',
      DomainFailureCode.sourceDisabled => '音乐来源已停用。',
      DomainFailureCode.sourceRemoved => '音乐来源已移除。',
      DomainFailureCode.streamUrlExpired => '播放地址已过期，请重新解析后再试。',
      DomainFailureCode.notFound => '未找到这首曲目。',
      DomainFailureCode.playbackOpenFailed => '无法打开音频，请检查来源后再试。',
      _ => '曲目暂时无法播放，请检查来源。',
    };
    return '$title · $source\n$reason';
  }
}
