import 'package:flutter/widgets.dart';

import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../design_system/yy_icon.dart';
import '../../../design_system/yy_surface.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/models/local_library_overview.dart';
import 'local_music_controller.dart';

/// Controlled read-only presentation; layout and live data remain separate.
final class LocalMusicSections {
  const LocalMusicSections({
    required this.controller,
    required this.canInteract,
  });
  final LocalMusicController controller;
  final bool Function() canInteract;

  Widget get heading => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('本地音乐概览', style: YYTypography.sectionTitle),
          YYButton(
            label: '刷新概览',
            glyph: YYGlyph.refresh,
            onPressed: controller.canRefresh
                ? () {
                    if (canInteract()) controller.refresh();
                  }
                : null,
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Text('以下统计来自已保存的本地索引，不代表当前文件访问权限。导入、扫描和重授权仍在开发。'),
      if (controller.phase == LoadPhase.loading ||
          controller.phase == LoadPhase.idle) ...[
        const SizedBox(height: 12),
        Semantics(liveRegion: true, child: const Text('正在读取本地索引…')),
        if (controller.content == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: YYSkeleton(height: 80),
          ),
      ],
      if (controller.failure != null) ...[
        const SizedBox(height: 12),
        YYErrorBanner(
          title: '本地概览暂不可用',
          message: controller.content == null
              ? '无法读取本地索引，请重试。'
              : '更新失败，下方保留上次结果，请重试。',
          actionLabel: '重试',
          onAction: controller.canRefresh
              ? () {
                  if (canInteract()) controller.refresh();
                }
              : null,
        ),
      ],
    ],
  );

  Widget metrics({required int columns}) {
    final data = controller.content;
    if (data == null) return const SizedBox.shrink();
    final values = [
      (
        '已入库歌曲',
        '${data.tracks.totalCount}',
        '可用记录 ${data.tracks.availableCount} · 不可用 ${data.tracks.unavailableCount}',
      ),
      (
        '本地文件夹',
        '${data.folderCount}',
        '启用配置 ${data.enabledFolderCount} · 非权限检查',
      ),
      ('总时长', '${data.tracks.totalDuration.inMinutes} 分钟', '按已保存曲目时长统计'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth < 320 ? 1 : columns;
        final width = (constraints.maxWidth - 12 * (count - 1)) / count;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (label, value, help) in values)
              SizedBox(
                width: width,
                child: YYSurface(
                  radius: YYRadius.metricCard,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: YYTypography.caption),
                      const SizedBox(height: 8),
                      Text(
                        value,
                        style: YYTypography.text(size: 24, weight: 750),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        help,
                        style: YYTypography.caption.copyWith(
                          color: YYTheme.of(context).colors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget get folders {
    final data = controller.content;
    if (data == null) return const SizedBox.shrink();
    return YYSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('已保存文件夹', style: YYTypography.sectionTitle),
          const SizedBox(height: 8),
          const Text('仅显示目录记录；不在这里展示路径或授权信息。'),
          const SizedBox(height: 12),
          if (data.folderCount == 0)
            const YYEmptyState(message: '暂无文件夹记录', glyph: YYGlyph.folder)
          else ...[
            Text(
              '第 ${data.page.offset + 1}–${data.page.offset + data.folders.length} 条，共 ${data.folderCount} 条',
            ),
            for (final folder in data.folders)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: YYSurface(
                  key: ValueKey(('local-folder', folder.id)),
                  radius: YYRadius.folderRow,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const YYIcon(glyph: YYGlyph.folder, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              folder.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: YYTypography.text(size: 12, weight: 700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_platform(folder.platform)} · ${folder.enabled ? '配置已启用' : '配置已停用'}',
                              style: YYTypography.caption,
                            ),
                            Text(
                              folder.lastScannedAt == null
                                  ? '尚无扫描记录 · 当前权限未验证'
                                  : '上次扫描记录 ${_date(folder.lastScannedAt!)} · 当前权限未验证',
                              style: YYTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                YYButton(
                  label: '上一页目录',
                  glyph: YYGlyph.up,
                  onPressed: controller.canPrevious
                      ? () {
                          if (canInteract()) controller.previous(data);
                        }
                      : null,
                ),
                YYButton(
                  label: '下一页目录',
                  glyph: YYGlyph.down,
                  onPressed: controller.canNext
                      ? () {
                          if (canInteract()) controller.next(data);
                        }
                      : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _platform(LocalFolderPlatform value) => switch (value) {
    LocalFolderPlatform.windows => 'Windows',
    LocalFolderPlatform.android => 'Android',
    LocalFolderPlatform.unknown => '未知平台',
  };
  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} UTC';
}
