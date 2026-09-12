part of 'app_router.dart';

extension _SleepSettingsRoute on AppRouter {
  void _openSleepSettings(
    PlaybackPresenter presenter,
    YYPlatform platform, {
    required AppRoute owner,
  }) {
    final navigator = _rootNavigator.currentState;
    if (_disposed ||
        _sleepDialog != null ||
        navigator == null ||
        _activePath != owner.path) {
      return;
    }
    final ownerPath = owner.path;
    late final RawDialogRoute<void> dialog;
    bool permitted() =>
        !_disposed &&
        identical(_sleepDialog, dialog) &&
        _activePath == ownerPath &&
        dialog.isCurrent;
    dialog = RawDialogRoute<void>(
      settings: const RouteSettings(name: 'playback-sleep-settings'),
      barrierDismissible: true,
      barrierLabel: '关闭播放设置',
      barrierColor: const Color(0x33000000),
      transitionDuration: Duration.zero,
      pageBuilder: (context, _, _) => Focus(
        onKeyEvent: (_, event) =>
            event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.space
            ? KeyEventResult.handled
            : KeyEventResult.ignored,
        child: SleepSettingsPanel(
          presenter: presenter,
          platform: platform,
          isCurrent: permitted,
          onClose: () {
            if (permitted()) _dismissSleepSettings();
          },
        ),
      ),
    );
    _sleepDialog = dialog;
    _sleepOwnerPath = ownerPath;
    unawaited(
      navigator.push<void>(dialog).whenComplete(() {
        if (identical(_sleepDialog, dialog)) {
          _sleepDialog = null;
          _sleepOwnerPath = null;
        }
      }),
    );
  }

  void _dismissSleepSettings() {
    final dialog = _sleepDialog;
    _sleepDialog = null;
    _sleepOwnerPath = null;
    if (dialog == null) return;
    // Revoke now; defer navigator mutation until its current update is finished.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = dialog.navigator;
      if (!_disposed &&
          navigator != null &&
          navigator.mounted &&
          dialog.isActive) {
        navigator.removeRoute(dialog);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}
