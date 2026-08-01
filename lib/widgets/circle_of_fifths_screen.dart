import 'package:flutter/material.dart' hide Interval, Key;
import 'package:keyline/model/modulation_vector.dart';
import 'package:keyline/widgets/circle_of_fifths_painter.dart';
import 'package:music_notes/music_notes.dart';

class CircleOfFifthsScreen extends StatefulWidget {
  const CircleOfFifthsScreen({super.key});

  @override
  State<CircleOfFifthsScreen> createState() => _CircleOfFifthsScreenState();
}

class _CircleOfFifthsScreenState extends State<CircleOfFifthsScreen> {
  List<ModulationVector> vectors = [
    Note.c.major.to(Note.e.minor),
    Note.e.minor.to(Note.f.minor),
    Note.f.minor.to(Note.g.flat.major),
    Note.g.flat.major.to(Note.b.major),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const .all(20),
          child: CircleOfFifthsPainter(vectors: vectors),
        ),
      ),
    );
  }
}
