import 'dart:developer' show inspect;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Interval, Key;
import 'package:keyline/model.dart';
import 'package:keyline/widgets/circle_of_fifths_painter.dart';
import 'package:keyline/widgets/screenshot_utils.dart';
import 'package:keyline/widgets/settings_modal.dart';

class CircleOfFifthsScreen extends StatefulWidget {
  const CircleOfFifthsScreen({
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
    this.initialVectors,
  });

  final String? initialVectors;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<CircleOfFifthsScreen> createState() => _CircleOfFifthsScreenState();
}

class _CircleOfFifthsScreenState extends State<CircleOfFifthsScreen>
    with TickerProviderStateMixin {
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
  late final AnimationController _timelineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  late final Animation<double> _timelineAnimation = CurvedAnimation(
    parent: _timelineController,
    curve: Curves.easeInOutCubic,
    reverseCurve: Curves.easeInOutCubic,
  );

  late _TimedSequence _sequence = _parseSequence(
    widget.initialVectors ?? _defaultInput,
  );
  VisualizationMode _visualizationMode = .circle2d;
  KeyNotationChoice _notationChoice = KeyNotationChoice.german;
  late final ValueNotifier<VisualizationDisplayOptions>
  _displayOptionsNotifier = .new(const VisualizationDisplayOptions());
  final GlobalKey _chartCaptureKey = GlobalKey();
  Offset _viewPan = .zero;
  double _rotationX = -0.82;
  double _rotationY = 0.22;

  bool get _is3dMode => _visualizationMode == .circle3d;

  static _TimedSequence _parseSequence(String input) {
    final entries = input
        .split(RegExp(r'[,\-\s]+'))
        .where((token) => token.isNotEmpty)
        .map(TimedKey.parse)
        .toList(growable: false);

    return _TimedSequence(entries);
  }

  Future<void> _setVisualizationMode(VisualizationMode mode) async {
    setState(() {
      _visualizationMode = mode;
    });

    if (mode == .timeline) {
      await _modeController.reverse();
      await _timelineController.forward();
      return;
    }

    await _timelineController.reverse();
    if (mode == .circle3d) {
      await _modeController.forward();
    } else {
      await _modeController.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _modeController.dispose();
    _timelineController.dispose();
    _displayOptionsNotifier.dispose();
    super.dispose();
  }

  Future<void> _showSettingsModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ValueListenableBuilder(
          valueListenable: _displayOptionsNotifier,
          builder: (context, displayOptions, _) {
            return SettingsModal(
              isDark: widget.themeMode == .dark,
              notationChoice: _notationChoice,
              displayOptions: displayOptions,
              onNotationChoiceChanged: (notationChoice) {
                setState(() {
                  _notationChoice = notationChoice;
                });
              },
              onDisplayOptionsChanged: (displayOptions) {
                _displayOptionsNotifier.value = displayOptions;
              },
              onThemeModeChanged: widget.onThemeModeChanged,
            );
          },
        );
      },
    );
  }

  Future<void> _captureChart() async {
    final filePath = await captureWidgetToFile(
      _chartCaptureKey,
      filename: buildCaptureFilename(),
    );

    if (!mounted) return;

    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save chart capture.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved chart capture to $filePath')),
    );
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
                  final _TimedSequence sequence;
                  try {
                    sequence = _parseSequence(value);
                  } on FormatException catch (e) {
                    inspect(e);

                    return;
                  }
                  setState(() {
                    _sequence = sequence;
                  });
                },
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Stack(
                  children: [
                    RepaintBoundary(
                      key: _chartCaptureKey,
                      child: Listener(
                        onPointerMove: _is3dMode
                            ? (event) {
                                setState(() {
                                  if (event.buttons
                                      case kSecondaryMouseButton ||
                                          kMiddleMouseButton) {
                                    _viewPan += event.delta;
                                  } else {
                                    _rotationY += event.delta.dx * 0.01;
                                    _rotationX =
                                        (_rotationX - event.delta.dy * 0.01)
                                            .clamp(-1.25, -0.08);
                                  }
                                });
                              }
                            : null,
                        child: AnimatedBuilder(
                          animation: .merge([
                            _modeAnimation,
                            _timelineAnimation,
                            _displayOptionsNotifier,
                          ]),
                          builder: (context, _) {
                            return CircleOfFifthsPainter(
                              vectors: _sequence.vectors,
                              timelineKeys: _sequence.keys,
                              visualizationMode: _visualizationMode,
                              depthProgress: _modeAnimation.value,
                              timelineProgress: _timelineAnimation.value,
                              viewPan: _viewPan,
                              rotationX: _rotationX,
                              rotationY: _rotationY,
                              notationSystem: _notationChoice.notationSystem,
                              displayOptions: _displayOptionsNotifier.value,
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const .symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: const .all(.circular(999)),
                        ),
                        child: Row(
                          mainAxisSize: .min,
                          children: [
                            IconButton(
                              onPressed: _captureChart,
                              icon: const Icon(Icons.photo_camera_outlined),
                              tooltip: 'Save chart capture',
                              padding: .zero,
                              visualDensity: .compact,
                            ),
                            const SizedBox(
                              height: 22,
                              child: VerticalDivider(thickness: 1.5, width: 20),
                            ),
                            SegmentedButton<VisualizationMode>(
                              showSelectedIcon: false,
                              style: const ButtonStyle(
                                visualDensity: .compact,
                                tapTargetSize: .shrinkWrap,
                                padding: WidgetStatePropertyAll<EdgeInsets>(
                                  .symmetric(horizontal: 10),
                                ),
                              ),
                              segments: const [
                                ButtonSegment(
                                  value: .circle3d,
                                  icon: Icon(Icons.view_in_ar_outlined),
                                  tooltip: 'Circle 3D',
                                ),
                                ButtonSegment(
                                  value: .circle2d,
                                  icon: Icon(Icons.radio_button_checked),
                                  tooltip: 'Circle 2D',
                                ),
                                ButtonSegment(
                                  value: .timeline,
                                  icon: Icon(Icons.timeline),
                                  tooltip: 'Timeline',
                                ),
                              ],
                              selected: {_visualizationMode},
                              onSelectionChanged: (selection) async {
                                await _setVisualizationMode(selection.single);
                              },
                            ),
                            const SizedBox(
                              height: 22,
                              child: VerticalDivider(thickness: 1.5, width: 20),
                            ),
                            IconButton(
                              onPressed: _showSettingsModal,
                              icon: const Icon(Icons.settings_outlined),
                              tooltip: 'Settings',
                              padding: .zero,
                              visualDensity: .compact,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimedSequence {
  _TimedSequence(this.keys) : vectors = keys.toModulationVectors();

  final List<TimedKey> keys;
  final List<ModulationVector> vectors;
}
