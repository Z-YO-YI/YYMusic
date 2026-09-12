import 'package:flutter/widgets.dart';

import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';

class WindowsQueueLayout extends StatelessWidget {
  const WindowsQueueLayout({
    super.key,
    required this.slivers,
    required this.scroll,
  });
  final List<Widget> slivers;
  final ScrollController scroll;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: YYTheme.of(context).colors.elevated,
            borderRadius: BorderRadius.circular(YYRadius.dialog),
            border: Border.all(color: YYTheme.of(context).colors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(YYRadius.dialog),
            child: CustomScrollView(
              controller: scroll,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(22),
                  sliver: SliverMainAxisGroup(slivers: slivers),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
