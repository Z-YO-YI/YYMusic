import 'package:flutter/widgets.dart';

import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_dialog.dart';
import '../../../design_system/yy_icon.dart';
import '../../../design_system/yy_search_field.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../domain/models/software_license.dart';
import '../../../domain/repositories/license_repository.dart';

/// Native license lookup; the injected repository owns framework/asset access.
class LicensesScreen extends StatefulWidget {
  const LicensesScreen({
    super.key,
    required this.repository,
    required this.onBack,
  });

  final LicenseRepository repository;
  final VoidCallback onBack;

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  final _query = TextEditingController();
  late Future<List<SoftwareLicense>> _licenses;

  @override
  void initState() {
    super.initState();
    _licenses = widget.repository.load();
  }

  @override
  void didUpdateWidget(LicensesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _licenses = widget.repository.load();
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _openText(SoftwareLicense license) {
    final theme = YYTheme.of(context);
    final phone = MediaQuery.sizeOf(context).width < 600;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭许可原文',
      transitionDuration: theme.motion(const Duration(milliseconds: 180)),
      pageBuilder: (context, _, _) {
        void close() => Navigator.of(context).pop();
        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(license.packages.join('\n')),
            const SizedBox(height: 20),
            Text(license.text, key: const ValueKey('complete-license-text')),
          ],
        );
        return YYTheme(
          data: theme,
          child: DefaultTextStyle(
            style: YYTypography.text(color: theme.colors.text)
                .copyWith(fontSize: 14, height: 1.5),
            child: SafeArea(
              child: Align(
                alignment: phone ? Alignment.bottomCenter : Alignment.center,
                child: phone
                    ? YYBottomSheet(title: '许可原文', body: body, onClose: close)
                    : YYDialog(title: '许可原文', body: body, onClose: close),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: YYTheme.of(context).colors.base,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                YYButton(label: '返回设置', onPressed: widget.onBack),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '开源许可',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('YYMusic 使用的开源组件。Android 标记表示该平台的原生依赖材料。'),
            const SizedBox(height: 16),
            YYSearchField(
              controller: _query,
              label: '搜索开源组件',
              placeholder: '输入组件名称',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<SoftwareLicense>>(
                future: _licenses,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Semantics(
                      liveRegion: true,
                      child: const Text('正在读取许可信息…'),
                    );
                  }
                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        const Text('无法读取许可信息，请重试。'),
                        YYButton(
                          label: '重试',
                          onPressed: () {
                            final request = widget.repository.load();
                            setState(() {
                              _licenses = request;
                            });
                          },
                        ),
                      ],
                    );
                  }
                  final licenses = snapshot.data;
                  if (licenses == null) {
                    return Semantics(
                      liveRegion: true,
                      child: const Text('正在读取许可信息…'),
                    );
                  }
                  final visible = licenses
                      .where((license) => license.matches(_query.text))
                      .toList();
                  if (visible.isEmpty) return const Text('没有匹配的组件');
                  return ListView.separated(
                    key: const PageStorageKey('license-components'),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final license = visible[index];
                      return YYButton(
                        label:
                            '${license.packages.first}${license.packages.length > 1 ? ' 等 ${license.packages.length} 个组件' : ''}',
                        glyph: YYGlyph.info,
                        onPressed: () => _openText(license),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
