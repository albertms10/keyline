import 'package:flutter/material.dart';

@immutable
class KeylineColors extends ThemeExtension<KeylineColors> {
  const KeylineColors({
    required this.majorToMajor,
    required this.minorToMinor,
    required this.majorToMinor,
    required this.minorToMajor,
    required this.chartRing,
    required this.chartInnerRing,
    required this.chartSpoke,
    required this.anchorFill,
    required this.anchorStroke,
    required this.primaryText,
    required this.secondaryText,
    required this.labelBackground,
    required this.legendText,
    required this.vectorLabelBackground,
    required this.surface,
  });

  final Color majorToMajor;
  final Color minorToMinor;
  final Color majorToMinor;
  final Color minorToMajor;
  final Color chartRing;
  final Color chartInnerRing;
  final Color chartSpoke;
  final Color anchorFill;
  final Color anchorStroke;
  final Color primaryText;
  final Color secondaryText;
  final Color labelBackground;
  final Color legendText;
  final Color vectorLabelBackground;
  final Color surface;

  static const light = KeylineColors(
    majorToMajor: Color(0xff1e6f68),
    minorToMinor: Color(0xff6a4c7b),
    majorToMinor: Color(0xffc54e4b),
    minorToMajor: Color(0xff2f6fae),
    chartRing: Color(0xff7d786c),
    chartInnerRing: Color(0xffb9ad96),
    chartSpoke: Color(0xffdfd7c7),
    anchorFill: Color(0xfffffcf5),
    anchorStroke: Color(0xff575148),
    primaryText: Color(0xff222826),
    secondaryText: Color(0xff6a4c7b),
    labelBackground: Color(0xf2fffcf5),
    legendText: Color(0xff3c3a35),
    vectorLabelBackground: Color(0xeafffcf5),
    surface: Color(0xfff7f3ea),
  );

  static const dark = KeylineColors(
    majorToMajor: Color(0xff5ac8c0),
    minorToMinor: Color(0xffb491ca),
    majorToMinor: Color(0xffff7b72),
    minorToMajor: Color(0xff5cb2ff),
    chartRing: Color(0xff9b927f),
    chartInnerRing: Color(0xff7b6f5b),
    chartSpoke: Color(0xff504a40),
    anchorFill: Color(0xff1d1a17),
    anchorStroke: Color(0xfff2ebdd),
    primaryText: Color(0xfff4ebdc),
    secondaryText: Color(0xffd3c1e5),
    labelBackground: Color(0xff24201b),
    legendText: Color(0xfff7efe5),
    vectorLabelBackground: Color(0xff2a241f),
    surface: Color(0xff181411),
  );

  @override
  KeylineColors copyWith({
    Color? majorToMajor,
    Color? minorToMinor,
    Color? majorToMinor,
    Color? minorToMajor,
    Color? chartRing,
    Color? chartInnerRing,
    Color? chartSpoke,
    Color? anchorFill,
    Color? anchorStroke,
    Color? primaryText,
    Color? secondaryText,
    Color? labelBackground,
    Color? legendText,
    Color? vectorLabelBackground,
    Color? surface,
  }) {
    return KeylineColors(
      majorToMajor: majorToMajor ?? this.majorToMajor,
      minorToMinor: minorToMinor ?? this.minorToMinor,
      majorToMinor: majorToMinor ?? this.majorToMinor,
      minorToMajor: minorToMajor ?? this.minorToMajor,
      chartRing: chartRing ?? this.chartRing,
      chartInnerRing: chartInnerRing ?? this.chartInnerRing,
      chartSpoke: chartSpoke ?? this.chartSpoke,
      anchorFill: anchorFill ?? this.anchorFill,
      anchorStroke: anchorStroke ?? this.anchorStroke,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      labelBackground: labelBackground ?? this.labelBackground,
      legendText: legendText ?? this.legendText,
      vectorLabelBackground:
          vectorLabelBackground ?? this.vectorLabelBackground,
      surface: surface ?? this.surface,
    );
  }

  @override
  KeylineColors lerp(ThemeExtension<KeylineColors>? other, double t) {
    if (other is! KeylineColors) return this;

    return KeylineColors(
      majorToMajor: Color.lerp(majorToMajor, other.majorToMajor, t)!,
      minorToMinor: Color.lerp(minorToMinor, other.minorToMinor, t)!,
      majorToMinor: Color.lerp(majorToMinor, other.majorToMinor, t)!,
      minorToMajor: Color.lerp(minorToMajor, other.minorToMajor, t)!,
      chartRing: Color.lerp(chartRing, other.chartRing, t)!,
      chartInnerRing: Color.lerp(chartInnerRing, other.chartInnerRing, t)!,
      chartSpoke: Color.lerp(chartSpoke, other.chartSpoke, t)!,
      anchorFill: Color.lerp(anchorFill, other.anchorFill, t)!,
      anchorStroke: Color.lerp(anchorStroke, other.anchorStroke, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      labelBackground: Color.lerp(labelBackground, other.labelBackground, t)!,
      legendText: Color.lerp(legendText, other.legendText, t)!,
      vectorLabelBackground: Color.lerp(
        vectorLabelBackground,
        other.vectorLabelBackground,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
    );
  }
}
