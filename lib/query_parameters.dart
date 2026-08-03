final class QueryParameters {
  const QueryParameters({this.keys, this.theme, this.mode});

  factory QueryParameters.fromUri(Uri uri) {
    final Uri(:queryParameters) = uri;

    return QueryParameters(
      keys: queryParameters[_keysParam],
      theme: queryParameters[_themeParam],
      mode: queryParameters[_modeParam],
    );
  }

  final String? keys;
  static const _keysParam = 'k';

  final String? theme;
  static const _themeParam = 't';

  final String? mode;
  static const _modeParam = 'm';

  Map<String, String> get queryParameters => {
    _keysParam: ?keys,
    _themeParam: ?theme,
    _modeParam: ?mode,
  };

  @override
  String toString() => Uri(queryParameters: queryParameters).toString();
}

final class ThemeQueryParameter {}
