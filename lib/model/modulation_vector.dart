import 'package:flutter/material.dart' show Color;
import 'package:music_notes/music_notes.dart';

/// A directed modulation between two tonal keys.
class ModulationVector {
  /// Creates a modulation vector.
  const ModulationVector({
    required this.from,
    required this.to,
    required this.color,
    required this.dashed,
    required this.label,
  });

  /// The source key.
  final Key from;

  /// The destination key.
  final Key to;

  /// The rendered arrow color.
  final Color color;

  /// Whether this vector is rendered as a dashed arrow.
  final bool dashed;

  /// The vector label.
  final String label;
}
