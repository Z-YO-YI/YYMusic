import 'package:flutter/widgets.dart';

import '../design_system/yy_button.dart';
import '../design_system/yy_icon.dart';
import 'fullscreen_presenter.dart';

/// Reuses the exported full-screen glyphs; no platform calls in page widgets.
class FullscreenButton extends StatelessWidget {
  const FullscreenButton({
    super.key,
    required this.presenter,
    required this.isCurrent,
  });
  final FullscreenPresenter? presenter;
  final bool Function() isCurrent;

  @override
  Widget build(BuildContext context) {
    final controller = presenter;
    if (controller == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => !controller.available
          ? const SizedBox.shrink()
          : YYButton(
              label: controller.enabled ? '退出全屏' : '进入全屏',
              glyph: controller.enabled
                  ? YYGlyph.fullscreenExit
                  : YYGlyph.fullscreen,
              iconOnly: true,
              selected: controller.enabled,
              loading: controller.busy,
              style: YYButtonStyle.quiet,
              onPressed: controller.canToggle
                  ? () {
                      if (isCurrent()) controller.toggle();
                    }
                  : null,
            ),
    );
  }
}
