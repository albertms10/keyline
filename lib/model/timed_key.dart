import 'package:keyline/model/modulation_vector.dart';
import 'package:music_notes/music_notes.dart';

/// A tonal key with an associated hold duration.
class TimedKey {
  /// Creates a timed tonal key.
  const TimedKey({required this.key, this.duration = 1});

  /// The tonal key.
  final Key key;

  /// Time spent in [key] before the next modulation.
  final double duration;
}

extension TimedKeyList on List<TimedKey> {
  /// Converts adjacent timed keys to modulation vectors.
  List<ModulationVector> toModulationVectors() => [
    for (int i = 0; i < length - 1; i++)
      this[i].key.to(this[i + 1].key, duration: this[i].duration),
  ];
}
