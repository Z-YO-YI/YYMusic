import 'package:flutter/widgets.dart';

class TabletQueueLayout extends StatelessWidget {
  const TabletQueueLayout({
    super.key,
    required this.slivers,
    required this.scroll,
    required this.landscape,
  });
  final List<Widget> slivers;
  final ScrollController scroll;
  final bool landscape;
  @override
  Widget build(BuildContext context) => Align(
    alignment: landscape ? Alignment.topRight : Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: CustomScrollView(
        controller: scroll,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverMainAxisGroup(slivers: slivers),
          ),
        ],
      ),
    ),
  );
}
