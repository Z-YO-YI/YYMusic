import 'package:flutter/widgets.dart';

import '../../design_system/yy_search_field.dart';
import '../../design_system/yy_segmented_control.dart';
import '../../design_system/yy_surface.dart';
import '../../design_system/yy_theme.dart';
import '../../design_system/yy_toggle.dart';
import '../../design_system/yy_tokens.dart';

/// User-entered, session-only text; no query request, fixture results or history.
class GalleryInputControls extends StatefulWidget {
  const GalleryInputControls({super.key});
  @override
  State<GalleryInputControls> createState() => _GalleryInputControlsState();
}

class _GalleryInputControlsState extends State<GalleryInputControls> {
  final _query = TextEditingController();
  var _filter = 'all';
  bool _loading = false;
  String? _submitted, _error;
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YYSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('输入与选择', style: YYTypography.sectionTitle),
        const SizedBox(height: 8),
        Text(
          '只演示输入、提交和筛选状态，不访问音乐服务或保存搜索历史。',
          style: YYTypography.caption.copyWith(
            color: YYTheme.of(context).colors.secondary,
          ),
        ),
        const SizedBox(height: 20),
        YYSearchField(
          key: const ValueKey('gallery-search'),
          controller: _query,
          label: '搜索输入示例',
          loading: _loading,
          errorText: _error,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (value) => setState(() {
            if (value.trim().isEmpty) {
              _error = '请输入搜索内容（仅本页示例）';
            } else {
              _submitted = value.trim();
              _error = null;
            }
          }),
        ),
        const SizedBox(height: 16),
        YYSegmentedControl<String>(
          label: '示例筛选',
          value: _filter,
          loading: _loading,
          segments: const [
            YYSegment(value: 'all', label: '全部'),
            YYSegment(value: 'tracks', label: '歌曲'),
            YYSegment(value: 'albums', label: '专辑'),
            YYSegment(value: 'artists', label: '歌手'),
          ],
          onChanged: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('展示加载状态（不请求网络）', style: YYTypography.caption)),
            const SizedBox(width: 12),
            YYToggle(
              key: const ValueKey('gallery-loading-toggle'),
              label: '展示加载状态',
              value: _loading,
              onChanged: (value) => setState(() => _loading = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _submitted == null ? '尚未提交示例搜索' : '已提交示例：$_submitted',
          key: const ValueKey('gallery-search-status'),
          style: YYTypography.caption,
        ),
      ],
    ),
  );
}
