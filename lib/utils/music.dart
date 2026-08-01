import 'package:music_notes/music_notes.dart';

List<Note> majorRingNotes() {
  // ignore: avoid_redundant_argument_values, specified by the app's model.
  final notes = Note.c.circleOfFifths(distance: 6);
  final byPitchClass = <int, Note>{};

  for (final note in notes) {
    byPitchClass.putIfAbsent(note.semitones.remainder(12), () => note);
  }

  return byPitchClass.values.toList(growable: false);
}
