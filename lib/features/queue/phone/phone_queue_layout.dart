import 'package:flutter/widgets.dart';

class PhoneQueueLayout extends StatelessWidget {
  const PhoneQueueLayout({
    super.key,
    required this.slivers,
    required this.scroll,
  });
  final List<Widget> slivers;
  final ScrollController scroll;
  @override
  Widget build(BuildContext context) => CustomScrollView(
    controller: scroll,
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverMainAxisGroup(slivers: slivers),
      ),
    ],
  );
}
