import 'package:flutter/gestures.dart';
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

class _CircleOfFifthsScreenState extends State<CircleOfFifthsScreen>
    with SingleTickerProviderStateMixin {
  static const _defaultInput = 'C e f Ges Ces';

  late final _controller = TextEditingController(
    text: widget.initialVectors ?? _defaultInput,
  );
  late final AnimationController _modeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final Animation<double> _modeAnimation = CurvedAnimation(
    parent: _modeController,
    curve: Curves.easeInOutCubic,
    reverseCurve: Curves.easeInOutCubic,
  );

  late List<ModulationVector> _vectors = _parseVectors(
    widget.initialVectors ?? _defaultInput,
  );
  bool _is3dMode = false;
  Offset _viewPan = .zero;
  double _rotationX = -0.82;
  double _rotationY = 0.22;

  static List<ModulationVector> _parseVectors(String input) => input
      .split(RegExp(r'[,\- ]+'))
      .map(Key.parse)
      .toList(growable: false)
      .toModulationVectors();

  @override
  void dispose() {
    _controller.dispose();
    _modeController.dispose();
    super.dispose();
  }

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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: .end,
                children: [
                  const Icon(Icons.view_in_ar_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Text('3D mode'),
                  const SizedBox(width: 8),
                  Switch(
                    value: _is3dMode,
                    onChanged: (value) async {
                      setState(() {
                        _is3dMode = value;
                      });
                      if (value) {
                        await _modeController.forward();
                      } else {
                        await _modeController.reverse();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Listener(
                  onPointerMove: _is3dMode
                      ? (event) {
                          setState(() {
                            if (event.buttons == kSecondaryMouseButton ||
                                event.buttons == kMiddleMouseButton) {
                              _viewPan += event.delta;
                            } else {
                              _rotationY += event.delta.dx * 0.01;
                              _rotationX = (_rotationX - event.delta.dy * 0.01)
                                  .clamp(
                                    -1.25,
                                    -0.08,
                                  );
                            }
                          });
                        }
                      : null,
                  child: AnimatedBuilder(
                    animation: _modeAnimation,
                    builder: (context, _) => CircleOfFifthsPainter(
                      vectors: _vectors,
                      depthProgress: _modeAnimation.value,
                      viewPan: _viewPan,
                      rotationX: _rotationX,
                      rotationY: _rotationY,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
