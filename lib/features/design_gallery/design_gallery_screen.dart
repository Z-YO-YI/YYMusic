import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../design_system/yy_button.dart';
import '../../design_system/yy_icon.dart';
import '../../design_system/yy_profile_header.dart';
import '../../design_system/yy_surface.dart';
import '../../design_system/yy_theme.dart';
import '../../design_system/yy_toggle.dart';
import '../../design_system/yy_tokens.dart';
import 'gallery_content_cards.dart';
import 'gallery_input_controls.dart';
import 'gallery_media_controls.dart';

/// An explicitly labelled component preview, not a fixture-backed music page.
class DesignGalleryScreen extends StatefulWidget {
  const DesignGalleryScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
  final _hex = TextEditingController(text: '#FF3B5C');
  final _hexFocus = FocusNode(debugLabel: 'Custom accent');
  String? _error;
  int _count = 0;
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    _hexFocus.addListener(_focusChanged);
  }

  void _focusChanged() => setState(() {});

  @override
  void dispose() {
    _hexFocus.removeListener(_focusChanged);
    _hexFocus.dispose();
    _hex.dispose();
    super.dispose();
  }

  void _applyAccent() {
    try {
      YYAppearanceScope.of(context).setCustomAccent(_hex.text);
      setState(() => _error = null);
      _hexFocus.unfocus();
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = YYAppearanceScope.of(context);
    final theme = YYTheme.of(context);
    final colors = theme.colors;
    final phone = MediaQuery.sizeOf(context).width < 600;
    return ScrollNotificationObserver(
      child: ColoredBox(
        color: colors.base,
        child: SafeArea(
          child: SingleChildScrollView(
            key: const PageStorageKey('design-gallery-scroll'),
            padding: EdgeInsets.fromLTRB(
              phone ? 20 : 32,
              20,
              phone ? 20 : 32,
              32 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        YYIconButton(
                          key: const ValueKey('gallery-back'),
                          glyph: YYGlyph.close,
                          label: '返回上一页',
                          onPressed: widget.onBack,
                          style: YYButtonStyle.quiet,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'YYMusic',
                            style: YYTypography.text(size: 16, weight: 760),
                          ),
                        ),
                        Text(
                          'ANDROID',
                          style: YYTypography.caption.copyWith(
                            color: colors.secondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '设计基础预览',
                      style: phone
                          ? YYTypography.phoneTitle
                          : YYTypography.pageTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Phase 2D · 原生组件\n仅验证设计与交互，尚未接入音乐库或播放。',
                      style: YYTypography.caption.copyWith(
                        color: colors.secondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const YYSurface(child: YYProfileHeader()),
                    const SizedBox(height: 24),
                    _Section(
                      title: '外观',
                      subtitle: '设置仅在本次运行生效，重启恢复默认。',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final (mode, label, glyph) in [
                                (YYThemeMode.light, '浅色', YYGlyph.sun),
                                (YYThemeMode.dark, '深色', YYGlyph.moon),
                                (YYThemeMode.system, '跟随系统', YYGlyph.device),
                              ])
                                YYButton(
                                  key: ValueKey('theme-${mode.name}'),
                                  label: label,
                                  glyph: glyph,
                                  selected: appearance.mode == mode,
                                  onPressed: () => appearance.setMode(mode),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('强调色', style: YYTypography.text(weight: 700)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final preset in YYAccentPreset.values)
                                YYButton(
                                  key: ValueKey('accent-${preset.name}'),
                                  label: preset.label,
                                  selected: appearance.accent.preset == preset,
                                  glyph: appearance.accent.preset == preset
                                      ? YYGlyph.check
                                      : null,
                                  onPressed: () => appearance.setPreset(preset),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '自定义 HEX',
                            style: YYTypography.caption.copyWith(
                              color: colors.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Semantics(
                                  label: '自定义强调色，六位 HEX',
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 44,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.base,
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(
                                        color: _hexFocus.hasFocus
                                            ? colors.text
                                            : colors.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: EditableText(
                                      key: const ValueKey(
                                        'custom-accent-input',
                                      ),
                                      controller: _hex,
                                      focusNode: _hexFocus,
                                      style: YYTypography.text(
                                        color: colors.text,
                                      ),
                                      cursorColor: colors.text,
                                      backgroundCursorColor: colors.border,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _applyAccent(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              YYButton(
                                key: const ValueKey('apply-accent'),
                                label: '应用',
                                onPressed: _applyAccent,
                              ),
                            ],
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _error!,
                                style: YYTypography.caption.copyWith(
                                  color: colors.text,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            '当前：${appearance.accent.originalHex} · ${theme.brightness == Brightness.dark ? '深色' : '浅色'}',
                            style: YYTypography.caption.copyWith(
                              color: colors.secondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '减少动态',
                                      style: YYTypography.text(weight: 680),
                                    ),
                                  ),
                                  YYToggle(
                                    key: const ValueKey('reduce-motion'),
                                    label: '减少动态',
                                    value: appearance.reduceMotion,
                                    onChanged: appearance.setReduceMotion,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '减少透明',
                                      style: YYTypography.text(weight: 680),
                                    ),
                                  ),
                                  YYToggle(
                                    key: const ValueKey('reduce-glass'),
                                    label: '减少透明',
                                    value: appearance.reduceGlass,
                                    onChanged: appearance.setReduceGlass,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            theme.reduceMotion
                                ? '动态效果已减少（含系统设置）。'
                                : '支持系统减少动态；可手动关闭过渡。',
                            style: YYTypography.caption.copyWith(
                              color: colors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: '控件状态',
                      subtitle: '按钮可点击；收藏是本页示例状态，不会修改曲库。',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              YYButton(
                                key: const ValueKey('demo-primary'),
                                label: '点击示例',
                                glyph: YYGlyph.plus,
                                style: YYButtonStyle.primary,
                                onPressed: () => setState(() => _count++),
                              ),
                              YYButton(
                                label: '次级按钮',
                                onPressed: () => setState(() => _count++),
                              ),
                              YYIconButton(
                                key: const ValueKey('demo-favorite'),
                                label: '示例收藏',
                                glyph: YYGlyph.heart,
                                selected: _favorite,
                                onPressed: () =>
                                    setState(() => _favorite = !_favorite),
                              ),
                              const YYButton(
                                label: '播放未接入',
                                glyph: YYGlyph.play,
                                onPressed: null,
                              ),
                              const YYButton(
                                label: '加载状态示例',
                                glyph: YYGlyph.more,
                                loading: true,
                                onPressed: null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              '已点击 $_count 次 · ${_favorite ? '示例已收藏' : '示例未收藏'}',
                              style: YYTypography.caption.copyWith(
                                color: colors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '触控目标 ≥44dp。外接键盘支持 Tab、Enter、Space；鼠标支持悬停。',
                            style: YYTypography.caption.copyWith(
                              color: colors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('局部玻璃表面', style: YYTypography.sectionTitle),
                    const SizedBox(height: 12),
                    YYGlassSurface(
                      height: 112,
                      child: Row(
                        children: [
                          YYIcon(
                            glyph: YYGlyph.music,
                            size: 28,
                            color: theme.accent.readableOn(colors.base),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '表面示例',
                                  style: YYTypography.text(weight: 700),
                                ),
                                Text(
                                  '播放未接入',
                                  style: YYTypography.caption.copyWith(
                                    color: colors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const YYIconButton(
                            glyph: YYGlyph.play,
                            label: '播放未接入',
                            onPressed: null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const GalleryMediaControls(),
                    const SizedBox(height: 24),
                    const GalleryInputControls(),
                    const SizedBox(height: 24),
                    const GalleryContentCards(),
                    const SizedBox(height: 24),
                    const GalleryArtworkSection(),
                    const SizedBox(height: 32),
                    _Section(
                      title: '原始图标 · 44',
                      subtitle: '来自 App.tsx 的 NEW_ICON_SPRITE，保留路径与 1.72 描边。',
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = (constraints.maxWidth / 96)
                              .floor()
                              .clamp(2, 8);
                          final width =
                              (constraints.maxWidth - (columns - 1) * 8) /
                              columns;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 16,
                            children: [
                              for (final glyph in YYGlyph.values)
                                SizedBox(
                                  width: width,
                                  child: Column(
                                    children: [
                                      YYIcon(
                                        glyph: glyph,
                                        size: 24,
                                        semanticLabel: glyph.label,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        glyph.assetName,
                                        textAlign: TextAlign.center,
                                        style: YYTypography.text(
                                          size: 10,
                                          weight: 500,
                                          color: colors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Inter / Noto Sans SC · 应用内字体\n参考网页视觉对照与 Android 真机验收仍待完成。',
                      style: YYTypography.caption.copyWith(
                        color: colors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => YYSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: YYTypography.sectionTitle),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: YYTypography.caption.copyWith(
            color: YYTheme.of(context).colors.secondary,
          ),
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}
