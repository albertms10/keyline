import 'package:flutter/material.dart';
import 'package:keyline/widgets/circle_of_fifths_painter.dart';
import 'package:keyline/widgets/settings_modal.dart';

final class QueryParameters {
  const QueryParameters({
    this.keys,
    this.visualizationMode = .circle2d,
    this.themeMode = .light,
    this.notationChoice = .german,
    this.displayOptions = const VisualizationDisplayOptions(),
  });

  factory QueryParameters.fromUri(Uri uri) {
    final Uri(:queryParameters) = uri;

    return QueryParameters(
      keys: queryParameters[_keysParam],
      visualizationMode: _parseVisualizationMode(queryParameters[_modeParam]),
      themeMode: _parseThemeMode(queryParameters[_themeParam]),
      notationChoice: _parseNotationChoice(queryParameters[_notationParam]),
      displayOptions: VisualizationDisplayOptions(
        showAxisKeyLabels: _parseBool(
          queryParameters[_axisKeysParam],
          fallback: true,
        ),
        showEdgeKeyLabels: _parseBool(
          queryParameters[_edgeKeysParam],
          fallback: true,
        ),
        showVectorLabels: _parseBool(
          queryParameters[_intervalLabelsParam],
          fallback: true,
        ),
        showDurationLabels: _parseBool(
          queryParameters[_durationLabelsParam],
          fallback: true,
        ),
        showGrid: _parseBool(queryParameters[_gridParam], fallback: true),
        showLegend: _parseBool(queryParameters[_legendParam], fallback: true),
      ),
    );
  }

  final String? keys;
  final VisualizationMode visualizationMode;
  final ThemeMode themeMode;
  final KeyNotationChoice notationChoice;
  final VisualizationDisplayOptions displayOptions;

  static const _keysParam = 'k';
  static const _modeParam = 'mode';
  static const _themeParam = 'theme';
  static const _notationParam = 'notation';
  static const _axisKeysParam = 'axisKeys';
  static const _edgeKeysParam = 'edgeKeys';
  static const _intervalLabelsParam = 'intervalLabels';
  static const _durationLabelsParam = 'durationLabels';
  static const _gridParam = 'grid';
  static const _legendParam = 'legend';

  QueryParameters copyWith({
    String? keys,
    bool clearKeys = false,
    VisualizationMode? visualizationMode,
    ThemeMode? themeMode,
    KeyNotationChoice? notationChoice,
    VisualizationDisplayOptions? displayOptions,
  }) {
    return QueryParameters(
      keys: clearKeys ? null : keys ?? this.keys,
      visualizationMode: visualizationMode ?? this.visualizationMode,
      themeMode: themeMode ?? this.themeMode,
      notationChoice: notationChoice ?? this.notationChoice,
      displayOptions: displayOptions ?? this.displayOptions,
    );
  }

  Map<String, String> get queryParameters => {
    _keysParam: ?keys,
    if (visualizationMode != .circle2d)
      _modeParam: visualizationMode.queryValue,
    if (themeMode != .light) _themeParam: themeMode.queryValue,
    if (notationChoice != .german)
      _notationParam: notationChoice.queryValue,
    if (!displayOptions.showAxisKeyLabels) _axisKeysParam: '0',
    if (!displayOptions.showEdgeKeyLabels) _edgeKeysParam: '0',
    if (!displayOptions.showVectorLabels) _intervalLabelsParam: '0',
    if (!displayOptions.showDurationLabels) _durationLabelsParam: '0',
    if (!displayOptions.showGrid) _gridParam: '0',
    if (!displayOptions.showLegend) _legendParam: '0',
  };

  @override
  String toString() => Uri(queryParameters: queryParameters).toString();

  static bool _parseBool(String? value, {required bool fallback}) {
    return switch (value?.toLowerCase()) {
      '1' || 'true' || 'yes' || 'on' => true,
      '0' || 'false' || 'no' || 'off' => false,
      _ => fallback,
    };
  }

  static VisualizationMode _parseVisualizationMode(String? value) {
    return switch (value?.toLowerCase()) {
      '3d' || 'circle3d' => .circle3d,
      'timeline' || 'tl' => .timeline,
      _ => .circle2d,
    };
  }

  static ThemeMode _parseThemeMode(String? value) {
    return switch (value?.toLowerCase()) {
      'dark' => .dark,
      _ => .light,
    };
  }

  static KeyNotationChoice _parseNotationChoice(String? value) {
    return switch (value?.toLowerCase()) {
      'english' || 'en' => .english,
      'romance' || 'rom' => .romance,
      _ => .german,
    };
  }
}

extension on VisualizationMode {
  String get queryValue {
    return switch (this) {
      .circle3d => '3d',
      .circle2d => '2d',
      .timeline => 'timeline',
    };
  }
}

extension on ThemeMode {
  String get queryValue {
    return switch (this) {
      .dark => 'dark',
      .light || .system => 'light',
    };
  }
}

extension on KeyNotationChoice {
  String get queryValue {
    return switch (this) {
      .english => 'english',
      .german => 'german',
      .romance => 'romance',
    };
  }
}
