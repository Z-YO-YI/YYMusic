import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

@immutable
class YYSegment<T> {
  const YYSegment({
    required this.value,
    required this.label,
    this.enabled = true,
  });
  final T value;
  final String label;
  final bool enabled;
}

/// A horizontally scrollable button group; tab/enter/space retain native focus.
class YYSegmentedControl<T> extends StatelessWidget {
  YYSegmentedControl({
    super.key,
    required this.label,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.loading = false,
  }) : assert(segments.length >= 2),
       assert(
         segments.map((segment) => segment.value).toSet().length ==
             segments.length,
       ),
       assert(segments.any((segment) => segment.value == value));
  final String label;
  final List<YYSegment<T>> segments;
  final T value;
  final ValueChanged<T>? onChanged;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    return Semantics(
      label: label,
      container: true,
      explicitChildNodes: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: theme.colors.subtle,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < segments.length; index++) ...[
                  if (index != 0) const SizedBox(width: 3),
                  YYControlAction(
                    key: ValueKey(segments[index].value),
                    label: segments[index].label,
                    selected: segments[index].value == value,
                    loading: loading,
                    onActivate: onChanged == null || !segments[index].enabled
                        ? null
                        : () {
                            if (segments[index].value != value) {
                              onChanged!(segments[index].value);
                            }
                          },
                    builder: (context, state) {
                      final selected = segments[index].value == value;
                      return AnimatedContainer(
                        duration: theme.motion(YYMotion.selected),
                        curve: YYMotion.standard,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: state.pressed
                              ? theme.colors.pressed
                              : selected
                              ? theme.colors.elevated
                              : state.hovered
                              ? theme.colors.pressed
                              : const Color(0x00000000),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: state.focused
                                ? theme.colors.text
                                : const Color(0x00000000),
                            width: 1.5,
                          ),
                          boxShadow: selected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x120F1214),
                                    offset: Offset(0, 3),
                                    blurRadius: 9,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          segments[index].label,
                          maxLines: 1,
                          style: YYTypography.text(
                            size: 11,
                            weight: 650,
                            color: selected
                                ? theme.colors.text
                                : theme.colors.secondary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
