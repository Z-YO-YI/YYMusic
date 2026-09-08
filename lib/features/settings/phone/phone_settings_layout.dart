import 'package:flutter/widgets.dart';

import '../../../design_system/yy_tokens.dart';
import '../common/settings_sections.dart';

/// Phone has compact horizontal categories above a single editable column.
class PhoneSettingsLayout extends StatelessWidget {
  const PhoneSettingsLayout({
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
    padding: const EdgeInsets.all(YYSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sections.header(context),
        sections.navigation(context, vertical: false),
        const SizedBox(height: YYSpace.lg),
        sections.panel(context),
      ],
    ),
  );
}
