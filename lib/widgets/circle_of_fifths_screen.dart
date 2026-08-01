import 'package:flutter/material.dart' hide Interval, Key;
import 'package:keyline/colors.dart';
import 'package:keyline/model/modulation_vector.dart';
import 'package:keyline/utils/music.dart';
import 'package:keyline/widgets/circle_of_fifths_painter.dart';
import 'package:music_notes/music_notes.dart';

class CircleOfFifthsScreen extends StatefulWidget {
  const CircleOfFifthsScreen({super.key});

  @override
  State<CircleOfFifthsScreen> createState() => _CircleOfFifthsScreenState();
}

class _CircleOfFifthsScreenState extends State<CircleOfFifthsScreen> {
  late final List<Key> _keys = _buildSelectableKeys();
  late Key _selectedKey = _keys.firstWhere((key) => key == Note.c.major);

  List<Key> _buildSelectableKeys() {
    final majorKeys = majorRingNotes()
        .map((note) => note.major.signature.keys[TonalMode.major]!)
        .toList(growable: false);
    final minorKeys = majorKeys
        .map((key) => key.signature.keys[TonalMode.minor]!)
        .toList(growable: false);

    return [...majorKeys, ...minorKeys];
  }

  @override
  Widget build(BuildContext context) {
    final vectors = _vectorsFor(_selectedKey);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const .all(20),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Circle of fifths',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: const Color(0xff263532),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: DropdownButtonFormField<Key>(
                      initialValue: _selectedKey,
                      decoration: const InputDecoration(
                        labelText: 'Starting key',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        for (final key in _keys)
                          DropdownMenuItem(
                            value: key,
                            child: Text(key.format()),
                          ),
                      ],
                      onChanged: (key) {
                        if (key == null) return;
                        setState(() => _selectedKey = key);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xfffffcf5),
                    border: Border.all(color: const Color(0xffd8d0bf)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CircleOfFifthsPainter(vectors: vectors),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<ModulationVector> _vectorsFor(Key startingKey) {
  return [
    _buildVector(startingKey, upAFifth: true, flipMode: false),
    _buildVector(startingKey, upAFifth: false, flipMode: false),
    _buildVector(startingKey, upAFifth: true, flipMode: true),
    _buildVector(startingKey, upAFifth: false, flipMode: true),
  ];
}

ModulationVector _buildVector(
  Key from, {
  required bool upAFifth,
  required bool flipMode,
}) {
  final interval = upAFifth ? Interval.P5 : Interval.P4;
  final targetMode = flipMode ? from.mode.parallel : from.mode;
  final targetNote = from.note.transposeBy(interval);
  final targetKey = Key(targetNote, targetMode);
  final color = switch ((from.mode, targetMode)) {
    (.major, .minor) => majorToMinorColor,
    (.minor, .major) => minorToMajorColor,
    (.major, .major) => majorToMajorColor,
    (.minor, .minor) => minorToMinorColor,
  };
  final direction = upAFifth ? 'up P5' : 'down P5';
  final modeChange = flipMode
      ? '${from.mode.format()} to ${targetMode.format()}'
      : targetMode.format();

  return ModulationVector(
    from: from,
    to: _canonicalKey(targetKey),
    color: color,
    dashed: !upAFifth,
    label: '$direction, $modeChange',
  );
}

Key _canonicalKey(Key key) {
  final signature = key.signature;
  return signature.keys[key.mode] ?? key;
}
