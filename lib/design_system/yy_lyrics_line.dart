import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

enum YYLyricsLineState { future, past, active }

/// Controlled full-screen lyric line. Activation only notifies a seek request.
class YYLyricsLine extends StatelessWidget {
  const YYLyricsLine({
    super.key,
    required this.text,
    required this.state,
    required this.onPressed,
    this.translation,
    this.loading = false,
    this.focusNode,
  });

  final String text;
  final String? translation;
  final YYLyricsLineState state;
  final VoidCallback? onPressed;
  final bool loading;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final active = state == YYLyricsLineState.active;
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final phone = mediaWidth < 600;
    final primarySize = phone
        ? (mediaWidth * .098).clamp(29.0, 43.0)
        : (mediaWidth * .05).clamp(34.0, 68.0);
    final translationSize = phone
        ? (mediaWidth * .038).clamp(12.0, 16.0)
        : (mediaWidth * .014).clamp(14.0, 20.0);
    final label = [
      if (active) '当前歌词',
      text,
      if (translation != null && translation!.isNotEmpty) translation!,
    ].join('，');

    return YYControlAction(
      label: label,
      onActivate: onPressed,
      selected: active,
      inMutuallyExclusiveGroup: false,
      loading: loading,
      focusNode: focusNode,
      builder: (context, interaction) {
        final theme = YYTheme.of(context);
        final Color lineColor;
        if (active) {
          lineColor = const Color(0xFFFFFFFF);
        } else if (interaction.pressed) {
          lineColor = const Color(0xB8FFFFFF);
        } else if (interaction.hovered) {
          lineColor = const Color(0x8FFFFFFF);
        } else if (state == YYLyricsLineState.past) {
          lineColor = const Color(0x80FFFFFF);
        } else {
          lineColor = const Color(0x3DFFFFFF);
        }
        final dotSize = phone
            ? YYQueueLyricsMetrics.phoneLyricsActiveDot
            : YYQueueLyricsMetrics.lyricsActiveDot;
        return AnimatedScale(
          duration: theme.motion(const Duration(milliseconds: 320)),
          curve: YYMotion.enter,
          alignment: Alignment.centerLeft,
          scale: active
              ? 1.018
              : interaction.pressed
              ? .995
              : 1,
          child: AnimatedContainer(
            key: const ValueKey('yy-lyrics-line-surface'),
            duration: theme.motion(const Duration(milliseconds: 280)),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: interaction.focused
                    ? const Color(0xD9FFFFFF)
                    : const Color(0x00FFFFFF),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (active) ...[
                  Padding(
                    padding: EdgeInsets.only(
                      top: primarySize * .58,
                      right: phone ? 10 : 14,
                    ),
                    child: Container(
                      key: const ValueKey('lyrics-active-dot'),
                      width: dotSize,
                      height: dotSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFFFFF),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14FFFFFF),
                            spreadRadius: YYQueueLyricsMetrics.lyricsActiveRing,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: theme.motion(
                          const Duration(milliseconds: 280),
                        ),
                        style: YYTypography.text(
                          size: primarySize,
                          weight: 780,
                          spacing: (-primarySize * .05).clamp(-1.9, -.45),
                          height: phone ? 1.14 : 1.12,
                          color: lineColor,
                        ),
                        child: Text(
                          loading ? '歌词加载中' : text,
                          textWidthBasis: TextWidthBasis.longestLine,
                        ),
                      ),
                      if (translation != null && translation!.isNotEmpty) ...[
                        SizedBox(height: phone ? 7 : 9),
                        Text(
                          translation!,
                          style: YYTypography.text(
                            size: translationSize,
                            weight: 570,
                            height: 1.35,
                            color: lineColor.withValues(
                              alpha: lineColor.a * .58,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
