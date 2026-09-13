import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_view_state.dart';
import '../../../app/layout_class.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../playback/continuation_persistence_controller.dart';
import '../phone/phone_settings_layout.dart';
import '../tablet/tablet_settings_layout.dart';
import '../windows/windows_settings_layout.dart';
import 'appearance_settings_controller.dart';
import 'settings_sections.dart';

/// Owns only a draft/editor and navigation presentation, never a second theme.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.platform,
    required this.controller,
    required this.navigation,
    required this.viewState,
    this.routeActive,
    this.continuation,
  });
  final YYPlatform platform;
  final AppearanceSettingsController controller;
  final AppNavigation navigation;
  final AppViewState viewState;
  final ContinuationPersistenceController? continuation;

  /// Borrowed app-level route visibility; no routing package enters this feature.
  final ValueListenable<bool>? routeActive;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _hex;
  late final ScrollController _scroll;
  final _hexFocus = FocusNode(debugLabel: 'Settings custom accent');
  final _panelKey = GlobalKey(debugLabel: 'Settings retained editor panel');
  final _viewportKey = GlobalKey(
    debugLabel: 'Settings retained scroll viewport',
  );
  SettingsSection _section = SettingsSection.appearance;
  bool _dirty = false, _active = true, _hasArea = true;
  int _generation = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hex = TextEditingController(
      text: widget.controller.appearance.accent.originalHex,
    );
    _scroll = ScrollController(
      initialScrollOffset: widget.viewState.scrollOffset(AppRoute.settings),
    )..addListener(_saveScroll);
    for (final section in SettingsSection.values) {
      if (widget.viewState.selection(AppRoute.settings) == section.name &&
          (section != SettingsSection.playback ||
              widget.continuation != null)) {
        _section = section;
      }
    }
    widget.continuation?.addListener(_continuationChanged);
    widget.controller.appearance.addListener(_appearanceChanged);
    widget.routeActive?.addListener(_routeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final active =
        size.width > 0 &&
        size.height > 0 &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (_active != active) {
      _active = active;
      _generation++;
      if (!active) _releaseEditorFocus();
    }
  }

  void _routeChanged() {
    if (!mounted) return;
    setState(() => _generation++);
    if (!_onSettingsRoute) _releaseEditorFocus();
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.continuation != widget.continuation) {
      oldWidget.continuation?.removeListener(_continuationChanged);
      widget.continuation?.addListener(_continuationChanged);
      _generation++;
      if (widget.continuation == null && _section == SettingsSection.playback) {
        _section = SettingsSection.appearance;
      }
    }
    if (oldWidget.routeActive != widget.routeActive) {
      oldWidget.routeActive?.removeListener(_routeChanged);
      widget.routeActive?.addListener(_routeChanged);
      _generation++;
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.appearance.removeListener(_appearanceChanged);
      widget.controller.appearance.addListener(_appearanceChanged);
      _generation++;
      _dirty = false;
      _error = null;
      _appearanceChanged();
    }
  }

  bool get _onSettingsRoute => widget.routeActive?.value ?? true;

  void _continuationChanged() {
    if (mounted) setState(() => _generation++);
  }

  void _releaseEditorFocus() {
    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _generation) _hexFocus.unfocus();
    });
  }

  bool _canInteract(int generation) {
    if (!mounted ||
        !_active ||
        !_hasArea ||
        !_onSettingsRoute ||
        generation != _generation) {
      return false;
    }
    final box = context.findRenderObject();
    return box is RenderBox &&
        box.hasSize &&
        box.size.width > 0 &&
        box.size.height > 0;
  }

  void _saveScroll() =>
      widget.viewState.saveScrollOffset(AppRoute.settings, _scroll.offset);

  void _appearanceChanged() {
    if (_dirty) return;
    final value = widget.controller.appearance.accent.originalHex;
    if (_hex.text != value) {
      _hex.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  void _apply() {
    if (!_hex.value.composing.isCollapsed) return;
    final value = _hex.text;
    if (value.length > 7 || !RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(value)) {
      setState(() => _error = '请输入 6 位十六进制颜色，例如 #FF3B5C');
      return;
    }
    setState(() {
      _dirty = false;
      _error = null;
    });
    widget.controller.appearance.setCustomAccent(value);
  }

  void _preset(YYAccentPreset value) {
    setState(() {
      _dirty = false;
      _error = null;
    });
    widget.controller.appearance.setPreset(value);
    _appearanceChanged();
  }

  @override
  void dispose() {
    _generation++;
    widget.routeActive?.removeListener(_routeChanged);
    widget.continuation?.removeListener(_continuationChanged);
    widget.controller.appearance.removeListener(_appearanceChanged);
    _scroll.removeListener(_saveScroll);
    _scroll.dispose();
    _hex.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final hasArea = constraints.maxWidth > 0 && constraints.maxHeight > 0;
      if (_hasArea != hasArea) {
        // A layout-only authorization epoch; never start I/O from layout/build.
        _hasArea = hasArea;
        _generation++;
        if (!hasArea) _releaseEditorFocus();
      }
      if (!hasArea) return const SizedBox.shrink();
      return ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final generation = _generation;
          final size = MediaQuery.sizeOf(context);
          final sections = SettingsSections(
            controller: widget.controller,
            continuation: widget.continuation,
            section: _section,
            panelKey: _panelKey,
            hex: _hex,
            hexFocus: _hexFocus,
            draft: _dirty,
            error: _error,
            enabled: _active && _onSettingsRoute,
            canInteract: () => _canInteract(generation),
            onDraft: (_) => setState(() {
              _dirty = true;
              _error = null;
            }),
            onApply: _apply,
            onPreset: _preset,
            onSection: (value) {
              if (_section == value) return;
              _hexFocus.unfocus();
              setState(() {
                _section = value;
                _generation++;
              });
              widget.viewState.select(AppRoute.settings, value.name);
              if (_scroll.hasClients) _scroll.jumpTo(0);
            },
            onLicenses: widget.navigation.openLicenses,
          );
          return ExcludeFocus(
            excluding: !_active || !_onSettingsRoute,
            child: widget.platform == YYPlatform.windows
                ? WindowsSettingsLayout(
                    sections: sections,
                    scroll: _scroll,
                    viewportKey: _viewportKey,
                  )
                : size.width < 600
                ? PhoneSettingsLayout(
                    sections: sections,
                    scroll: _scroll,
                    viewportKey: _viewportKey,
                  )
                : TabletSettingsLayout(
                    sections: sections,
                    scroll: _scroll,
                    viewportKey: _viewportKey,
                    landscape: size.width > size.height,
                  ),
          );
        },
      );
    },
  );
}
