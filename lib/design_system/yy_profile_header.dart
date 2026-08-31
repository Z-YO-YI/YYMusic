import 'package:flutter/widgets.dart';

import 'yy_theme.dart';
import 'yy_tokens.dart';

/// The local-account fixture is not the application name or a signed-in user.
class YYProfileHeader extends StatelessWidget {
  const YYProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return MergeSemantics(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.text,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: colors.border, spreadRadius: 3.5),
                BoxShadow(color: colors.elevated, spreadRadius: 2),
              ],
            ),
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child: Text(
                'YY',
                style: YYTypography.text(
                  size: 15,
                  weight: 800,
                  spacing: -1.5,
                  color: colors.elevated,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YYListener', style: YYTypography.accountName),
                const SizedBox(height: 2),
                Text(
                  '本地账户',
                  style: YYTypography.accountSubtitle.copyWith(
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
