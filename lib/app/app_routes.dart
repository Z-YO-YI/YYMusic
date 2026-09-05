enum AppRoute {
  home('/home', '首页'),
  search('/search', '搜索'),
  library('/library', '音乐库'),
  settings('/settings', '设置'),
  player('/player', '播放路由'),
  lyrics('/lyrics', '歌词路由');

  const AppRoute(this.path, this.label);
  final String path;
  final String label;

  static const mainRoutes = [home, search, library, settings];
  bool get isMain => mainRoutes.contains(this);
}

/// Features use this contract, not GoRouter or plugin-specific route types.
abstract interface class AppNavigation {
  void goTo(AppRoute route);
  void openPlayer();
  void openLyrics();
  void openDesignGallery();
  void openLicenses();
  void back();
}
