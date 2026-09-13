import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';

/// Read-only display. The host owns route/visibility permission; the root owns
/// the business deadline. Rebuilding this child never rebuilds host actions.
class SleepRemainingText extends StatefulWidget {
  const SleepRemainingText({
    super.key,
    required this.presenter,
    required this.active,
    required this.isCurrent,
  });

  final PlaybackPresenter presenter;
  final bool active;
  final bool Function() isCurrent;

  @override
  State<SleepRemainingText> createState() => _SleepRemainingTextState();
}

class _SleepRemainingTextState extends State<SleepRemainingText>
    with WidgetsBindingObserver {
  Timer? _refresh;
  int _revision = 0;
  int? _seconds;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    widget.presenter.addListener(_restart);
    _restart();
  }

  @override
  void didUpdateWidget(SleepRemainingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presenter != widget.presenter) {
      oldWidget.presenter.removeListener(_restart);
      widget.presenter.addListener(_restart);
    }
    _restart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _restart();
  }

  void _restart() {
    _refresh?.cancel();
    _refresh = null;
    final revision = ++_revision;
    // Host permission may inspect its laid-out RenderBox.
    WidgetsBinding.instance.addPostFrameCallback((_) => _read(revision));
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  bool _allowed(int revision) {
    if (!mounted || revision != _revision || !widget.active || !_foreground) {
      return false;
    }
    try {
      return widget.isCurrent() && mounted && revision == _revision;
    } catch (_) {
      return false;
    }
  }

  void _read(int revision) {
    if (!mounted || revision != _revision) return;
    final seconds = _allowed(revision)
        ? widget.presenter.sleepRemainingSeconds
        : null;
    if (_seconds != seconds) setState(() => _seconds = seconds);
    if (seconds != null && seconds > 0) {
      _refresh = Timer(const Duration(seconds: 1), () => _read(revision));
    }
  }

  @override
  void dispose() {
    _revision++;
    _refresh?.cancel();
    widget.presenter.removeListener(_restart);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _seconds;
    if (seconds == null || !widget.active || !_foreground) {
      return const SizedBox.shrink();
    }
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return Semantics(
      liveRegion: false,
      child: Text(
        '剩余 $minutes:$remainder',
        style: YYTypography.caption.copyWith(
          color: YYTheme.of(context).colors.secondary,
        ),
      ),
    );
  }
}
