import 'package:flutter/material.dart' hide Interval, Key;
import 'package:keyline/model/modulation_vector.dart';
import 'package:keyline/widgets/circle_of_fifths_painter.dart';
import 'package:music_notes/music_notes.dart';

class CircleOfFifthsScreen extends StatefulWidget {
  const CircleOfFifthsScreen({super.key, this.initialVectors});

  final String? initialVectors;

  @override
  State<CircleOfFifthsScreen> createState() => _CircleOfFifthsScreenState();
}

class _CircleOfFifthsScreenState extends State<CircleOfFifthsScreen> {
  static const _defaultInput = 'C e f Ges Ces';

  late final _controller = TextEditingController(
    text: widget.initialVectors ?? _defaultInput,
  );

  late List<ModulationVector> _vectors = _parseVectors(
    widget.initialVectors ?? _defaultInput,
  );

  static List<ModulationVector> _parseVectors(String input) => input
      .split(RegExp(r'[,\- ]+'))
      .map(Key.parse)
      .toList(growable: false)
      .toModulationVectors();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const .all(20),
          child: Column(
            mainAxisSize: .min,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: _defaultInput,
                  filled: true,
                ),
                onChanged: (value) {
                  final List<ModulationVector> vectors;
                  try {
                    vectors = _parseVectors(value);
                  } on FormatException {
                    return;
                  }
                  setState(() {
                    _vectors = vectors;
                  });
                },
              ),
              const SizedBox(height: 20),
              Expanded(child: CircleOfFifthsPainter(vectors: _vectors)),
            ],
          ),
        ),
      ),
    );
  }
}
