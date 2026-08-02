import 'package:flutter/material.dart' show Color;
import 'package:keyline/colors.dart';
import 'package:music_notes/music_notes.dart';
import 'package:music_notes/utils.dart';

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
  Color colorFor(KeylineColors colors) => switch ((from.mode, to.mode)) {
    (.major, .minor) => colors.majorToMinor,
    (.minor, .major) => colors.minorToMajor,
    (.major, .major) => colors.majorToMajor,
    (.minor, .minor) => colors.minorToMinor,
  };

  /// Whether this vector is rendered as a dashed arrow.
  bool get dashed => to.signature.distance! - from.signature.distance! < 0;

  /// The vector label.
  String get label =>
      (to.signature.distance! - from.signature.distance!).toDeltaString();
}

extension KeyModulationVector on Key {
  ModulationVector to(Key targetKey) =>
      ModulationVector(from: this, to: targetKey);
}

extension KeyList on List<Key> {
  List<ModulationVector> toModulationVectors() => [
    for (int i = 0; i < length - 1; i++) this[i].to(this[i + 1]),
  ];
}
