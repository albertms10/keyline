import 'package:flutter/material.dart' show Color;
import 'package:keyline/colors.dart';
import 'package:music_notes/music_notes.dart';

/// A directed modulation between two tonal keys.
class ModulationVector {
  /// Creates a modulation vector.
  const ModulationVector({
    required this.from,
    required this.to,
  });

  /// The source key.
  final Key from;

  /// The destination key.
  final Key to;

  /// The rendered arrow color.
  Color get color => switch ((from.mode, to.mode)) {
    (.major, .minor) => majorToMinorColor,
    (.minor, .major) => minorToMajorColor,
    (.major, .major) => majorToMajorColor,
    (.minor, .minor) => minorToMinorColor,
  };

  /// Whether this vector is rendered as a dashed arrow.
  bool get dashed => to.signature.distance! - from.signature.distance! < 0;

  /// The vector label.
  String get label =>
      '${to.signature.distance! - from.signature.distance!} fifths';
}

extension KeyModulationVector on Key {
  ModulationVector to(Key targetKey) =>
      ModulationVector(from: this, to: targetKey);
}
