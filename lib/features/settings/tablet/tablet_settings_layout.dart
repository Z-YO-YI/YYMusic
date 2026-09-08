import 'package:flutter/widgets.dart';

import '../../../design_system/yy_tokens.dart';
import '../common/settings_sections.dart';

/// Tablet switches from portrait categories to a landscape master-detail grid.
class TabletSettingsLayout extends StatelessWidget {
  const TabletSettingsLayout({
    super.key,
    required this.sections,
    required this.scroll,
    required this.viewportKey,
    required this.landscape,
  });
  final SettingsSections sections;
  final ScrollController scroll;
  final GlobalKey viewportKey;
  final bool landscape;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: viewportKey,
    controller: scroll,
    padding: EdgeInsets.all(landscape ? YYSpace.xxl : YYSpace.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sections.header(context),
        if (landscape)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 176,
                child: sections.navigation(context, vertical: true),
              ),
              const SizedBox(width: YYSpace.lg),
              Expanded(child: sections.panel(context)),
            ],
          )
        else ...[
          sections.navigation(context, vertical: false),
          const SizedBox(height: YYSpace.lg),
          sections.panel(context),
        ],
      ],
    ),
  );
}
