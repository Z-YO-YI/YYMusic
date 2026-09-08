import 'package:flutter/widgets.dart';

import '../../../design_system/yy_tokens.dart';
import '../common/settings_sections.dart';

/// Desktop retains category/content columns independently of Android width rules.
class WindowsSettingsLayout extends StatelessWidget {
  const WindowsSettingsLayout({
    super.key,
    required this.sections,
    required this.scroll,
    required this.viewportKey,
  });
  final SettingsSections sections;
  final ScrollController scroll;
  final GlobalKey viewportKey;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: viewportKey,
    controller: scroll,
    padding: const EdgeInsets.all(YYSpace.xxl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sections.header(context),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 540
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    sections.navigation(context, vertical: false),
                    const SizedBox(height: YYSpace.lg),
                    sections.panel(context),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 176,
                      child: sections.navigation(context, vertical: true),
                    ),
                    const SizedBox(width: YYSpace.lg),
                    Expanded(child: sections.panel(context)),
                  ],
                ),
        ),
      ],
    ),
  );
}
