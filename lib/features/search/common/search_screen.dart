import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_view_state.dart';
import '../../../app/layout_class.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_theme.dart';
import '../phone/phone_search_layout.dart';
import '../tablet/tablet_search_layout.dart';
import '../windows/windows_search_layout.dart';
import 'search_controller.dart';
import 'search_sections.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.platform,
    required this.controller,
    required this.playback,
    required this.navigation,
    required this.viewState,
  });
  final YYPlatform platform;
  final CatalogSearchController controller;
  final PlaybackPresenter playback;
  final AppNavigation navigation;
  final AppViewState viewState;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _input;
  late final ScrollController _scroll;
  final _focus = FocusNode(debugLabel: 'catalog-search');
  int _lastFocus = 0;
  bool _active = true;
  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.controller.input)
      ..addListener(_edited);
    _scroll = ScrollController(
      initialScrollOffset: widget.viewState.scrollOffset(AppRoute.search),
    )..addListener(_save);
    widget.controller.addListener(_changed);
    widget.controller.start();
    _changed();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _active = TickerMode.valuesOf(context).enabled;
    widget.controller.setActive(_active);
    if (!_active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_active) _focus.unfocus();
      });
    } else {
      _changed();
    }
  }

  void _edited() => widget.controller.updateInput(
    _input.text,
    composing:
        _input.value.composing.isValid && !_input.value.composing.isCollapsed,
  );
  void _changed() {
    if (_input.text != widget.controller.input) {
      final text = widget.controller.input;
      _input.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    if (widget.controller.focusRequest != _lastFocus && _active) {
      _lastFocus = widget.controller.focusRequest;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _active) {
          if (_scroll.hasClients) _scroll.jumpTo(0);
          _focus.requestFocus();
        }
      });
    }
  }

  void _save() =>
      widget.viewState.saveScrollOffset(AppRoute.search, _scroll.offset);
  @override
  void dispose() {
    widget.controller.setActive(false);
    widget.controller.removeListener(_changed);
    _input.removeListener(_edited);
    _input.dispose();
    _focus.dispose();
    _scroll.removeListener(_save);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: YYTheme.of(context).colors.base,
    child: ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.playback]),
      builder: (context, _) {
        final size = MediaQuery.sizeOf(context);
        final sections = SearchSections(
          controller: widget.controller,
          playback: widget.playback,
          input: _input,
          focus: _focus,
          navigation: widget.navigation,
          submit: () => unawaited(widget.controller.submit()),
        );
        if (widget.platform == YYPlatform.windows) {
          return WindowsSearchLayout(sections: sections, scroll: _scroll);
        }
        if (size.width < 600) {
          return PhoneSearchLayout(sections: sections, scroll: _scroll);
        }
        return TabletSearchLayout(
          sections: sections,
          scroll: _scroll,
          landscape: size.width > size.height,
        );
      },
    ),
  );
}
