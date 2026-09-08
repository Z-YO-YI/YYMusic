import 'package:flutter/widgets.dart';

import '../../../design_system/src/yy_control_action.dart';
import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../design_system/yy_icon.dart';
import '../../../design_system/yy_segmented_control.dart';
import '../../../design_system/yy_surface.dart';
import '../../../design_system/yy_text_field.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_theme_swatch.dart';
import '../../../design_system/yy_toggle.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../domain/models/load_state.dart';
import 'appearance_settings_controller.dart';

enum SettingsSection {
  appearance('外观', YYGlyph.palette),
  about('关于 YYMusic', YYGlyph.info);

  const SettingsSection(this.label, this.glyph);
  final String label;
  final YYGlyph glyph;
}

/// Shared controlled content. Platform layouts arrange it without owning state.
final class SettingsSections {
  const SettingsSections({
    required this.controller,
    required this.section,
    required this.panelKey,
    required this.hex,
    required this.hexFocus,
    required this.draft,
    required this.error,
    required this.enabled,
    required this.canInteract,
    required this.onDraft,
    required this.onApply,
    required this.onPreset,
    required this.onSection,
    required this.onLicenses,
  });
  final AppearanceSettingsController controller;
  final SettingsSection section;
  final GlobalKey panelKey;
  final TextEditingController hex;
  final FocusNode hexFocus;
  final bool draft, enabled;
  final String? error;
  final bool Function() canInteract;
  final ValueChanged<String> onDraft;
  final VoidCallback onApply, onLicenses;
  final ValueChanged<YYAccentPreset> onPreset;
  final ValueChanged<SettingsSection> onSection;
  bool get _editable => enabled && (!controller.persistent || controller.ready);

  VoidCallback? _action(VoidCallback action, {bool edit = false}) =>
      !enabled || (edit && !_editable)
      ? null
      : () {
          if (canInteract() && (!edit || _editable)) action();
        };

  Widget header(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: YYSpace.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('设置', style: YYTypography.pageTitle),
        const SizedBox(height: YYSpace.sm),
        Text(
          '外观与本机偏好',
          style: YYTypography.caption.copyWith(
            color: YYTheme.of(context).colors.secondary,
          ),
        ),
      ],
    ),
  );

  Widget navigation(BuildContext context, {required bool vertical}) {
    final theme = YYTheme.of(context);
    final items = [
      for (final item in SettingsSection.values)
        YYControlAction(
          key: ValueKey('settings-section-${item.name}'),
          label: item.label,
          selected: section == item,
          onActivate: _action(() => onSection(item)),
          builder: (context, state) {
            final selected = section == item;
            final fill = selected
                ? Color.alphaBlend(theme.accent.soft, theme.colors.elevated)
                : state.pressed || state.hovered
                ? theme.colors.subtle
                : theme.colors.elevated;
            final color = selected
                ? theme.accent.readableOn(fill)
                : theme.colors.secondary;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: YYSpace.md,
                vertical: YYSpace.md,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(
                  YYRadius.settingsNavigation,
                ),
                border: Border.all(
                  color: state.focused
                      ? theme.colors.text
                      : const Color(0x00000000),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: vertical ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  YYIcon(glyph: item.glyph, size: 18, color: color),
                  const SizedBox(width: YYSpace.sm),
                  Flexible(
                    child: Text(
                      item.label,
                      style: YYTypography.text(
                        size: 12,
                        weight: 650,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
    ];
    return YYSurface(
      padding: const EdgeInsets.all(YYSpace.sm),
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: items),
            ),
    );
  }

  Widget panel(BuildContext context) => YYSurface(
    key: panelKey,
    child: section == SettingsSection.appearance
        ? _appearance(context)
        : _about(context),
  );

  Widget _copy(BuildContext context, String text) => Text(
    text,
    style: YYTypography.text(
      size: 11,
      height: 1.65,
      color: YYTheme.of(context).colors.secondary,
    ),
  );

  Widget _status(BuildContext context) {
    if (controller.failure != null) {
      return YYErrorBanner(
        key: const ValueKey('settings-storage-error'),
        title: controller.ready ? '外观设置尚未保存' : '无法读取外观设置',
        message: controller.ready
            ? '当前外观已生效，重试后将保存最新设置。'
            : '原有设置未被覆盖。请重试读取后再修改外观。',
        actionLabel: '重试',
        onAction: _action(controller.retry),
      );
    }
    final String status;
    if (!controller.persistent) {
      status = '仅本次会话生效';
    } else if (!controller.ready || controller.phase == LoadPhase.loading) {
      status = '正在读取外观设置…';
    } else if (controller.saving || controller.unsaved) {
      status = '正在保存外观设置…';
    } else {
      status = '外观设置已保存到本机';
    }
    return Semantics(liveRegion: true, child: _copy(context, status));
  }

  Widget _appearance(BuildContext context) {
    final appearance = controller.appearance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('外观', style: YYTypography.sectionTitle),
        const SizedBox(height: YYSpace.sm),
        _copy(context, '默认使用浅色外观，也可以跟随系统或选择自定义主题色。'),
        const SizedBox(height: YYSpace.md),
        _status(context),
        _SettingsRow(
          label: '显示模式',
          help: '切换浅色、深色或跟随操作系统。',
          child: YYSegmentedControl<YYThemeMode>(
            label: '显示模式',
            segments: const [
              YYSegment(value: YYThemeMode.light, label: '浅色'),
              YYSegment(value: YYThemeMode.dark, label: '深色'),
              YYSegment(value: YYThemeMode.system, label: '系统'),
            ],
            value: appearance.mode,
            onChanged: !_editable
                ? null
                : (value) {
                    _action(
                      () => appearance.setMode(value),
                      edit: true,
                    )?.call();
                  },
          ),
        ),
        _SettingsRow(
          label: '主题色',
          help: '影响主按钮、选中状态与播放进度。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: YYSpace.xs,
                runSpacing: YYSpace.xs,
                children: [
                  for (final preset in YYAccentPreset.values)
                    YYThemeSwatch(
                      label: preset.label,
                      color: Color(preset.argb),
                      selected: appearance.accent.preset == preset,
                      onPressed: _action(() => onPreset(preset), edit: true),
                    ),
                ],
              ),
              const SizedBox(height: YYSpace.sm),
              _copy(
                context,
                '当前：${appearance.accent.preset?.label ?? '自定义'} · ${appearance.accent.originalHex}',
              ),
            ],
          ),
        ),
        _SettingsRow(
          label: '自定义主题色',
          help: '输入六位 Hex 并应用，文字对比度会自动调整。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              YYTextField(
                key: const ValueKey('settings-custom-hex'),
                controller: hex,
                focusNode: hexFocus,
                label: '颜色 Hex',
                placeholder: '#FF3B5C',
                enabled: _editable,
                errorText: error,
                onChanged: (value) {
                  _action(() => onDraft(value), edit: true)?.call();
                },
                onSubmitted: (_) {
                  _action(onApply, edit: true)?.call();
                },
              ),
              const SizedBox(height: YYSpace.sm),
              Wrap(
                spacing: YYSpace.sm,
                runSpacing: YYSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  YYButton(
                    label: '应用颜色',
                    style: YYButtonStyle.primary,
                    onPressed: _action(onApply, edit: true),
                  ),
                  if (draft) _copy(context, '颜色草稿尚未应用'),
                ],
              ),
            ],
          ),
        ),
        _SettingsRow(
          label: 'Liquid Glass 导航',
          help: '仅用于导航、播放器及临时操作层；关闭可降低玻璃效果。',
          compact: true,
          child: YYToggle(
            label: 'Liquid Glass 导航',
            value: !appearance.reduceGlass,
            onChanged: !_editable
                ? null
                : (value) {
                    _action(
                      () => appearance.setReduceGlass(!value),
                      edit: true,
                    )?.call();
                  },
          ),
        ),
        _SettingsRow(
          label: '减少动态效果',
          help: '降低页面与播放界面的位移动画；同时尊重系统减少动态效果。',
          compact: true,
          child: YYToggle(
            label: '减少动态效果',
            value: appearance.reduceMotion,
            onChanged: !_editable
                ? null
                : (value) {
                    _action(
                      () => appearance.setReduceMotion(value),
                      edit: true,
                    )?.call();
                  },
          ),
        ),
      ],
    );
  }

  Widget _about(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('关于 YYMusic', style: YYTypography.sectionTitle),
      const SizedBox(height: YYSpace.sm),
      _copy(context, 'Windows、Android 手机与平板的原生 Flutter 音乐播放器。'),
      _SettingsRow(
        label: '开发测试版本',
        help: '尚未完成正式发布验收。',
        child: _copy(context, '真实文件导入与扫描、完整播放和歌词页面、后台媒体能力仍在开发。'),
      ),
      _SettingsRow(
        label: '本机存储',
        help: '外观偏好与曲库索引由应用在本机管理。',
        child: _copy(context, '只有已保存的设置会在下次启动恢复；颜色草稿不会自动保存。'),
      ),
      _SettingsRow(
        label: '内容与版权',
        help: 'YYMusic 不提供曲库或内容分发。',
        child: _copy(context, '在线内容需由用户配置拥有合法访问权限的来源；不提供下载或离线保存。'),
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: YYButton(
          label: '开源许可',
          glyph: YYGlyph.info,
          onPressed: _action(onLicenses),
        ),
      ),
    ],
  );
}

/// A single reusable reference setting row, stacked when the content is narrow.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.help,
    required this.child,
    this.compact = false,
  });
  final String label, help;
  final Widget child;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: YYSpace.lg),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: YYTheme.of(context).colors.border),
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: YYTypography.text(size: 12, weight: 650)),
            const SizedBox(height: YYSpace.xs),
            Text(
              help,
              style: YYTypography.text(
                size: 10,
                height: 1.6,
                color: YYTheme.of(context).colors.secondary,
              ),
            ),
          ],
        );
        final wide = constraints.maxWidth >= 520;
        return wide || compact
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: YYSpace.lg),
                  if (compact)
                    child
                  else
                    SizedBox(
                      width: constraints.maxWidth >= 600 ? 300 : 260,
                      child: child,
                    ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  copy,
                  const SizedBox(height: YYSpace.md),
                  child,
                ],
              );
      },
    ),
  );
}
