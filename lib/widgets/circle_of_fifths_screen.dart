import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Interval, Key;
import 'package:keyline/model.dart';
import 'package:keyline/widgets/circle_of_fifths_painter.dart';
import 'package:keyline/widgets/settings_modal.dart';
import 'package:music_notes/music_notes.dart';

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
  late final ValueNotifier<StringNotationSystem<Key>> _notationSystemNotifier =
      .new(const GermanKeyNotation());
  late final ValueNotifier<VisualizationDisplayOptions>
  _displayOptionsNotifier = .new(const VisualizationDisplayOptions());
  Offset _viewPan = .zero;
  double _rotationX = -0.82;
  double _rotationY = 0.22;

  bool get _is3dMode => _visualizationMode == .circle3d;

  static _TimedSequence _parseSequence(String input) {
    final entries = input
        .split(RegExp(r'[,\-\s]+'))
        .where((token) => token.isNotEmpty)
        .map(_parseTimedKey)
        .toList(growable: false);

    return _TimedSequence(entries);
  }

  static TimedKey _parseTimedKey(String token) {
    final separatorIndex = token.lastIndexOf(RegExp('[:=]'));
    if (separatorIndex < 0) return TimedKey(key: Key.parse(token));

    final duration = double.parse(token.substring(separatorIndex + 1));
    if (duration <= 0) {
      throw FormatException('Duration must be positive', token);
    }

    return TimedKey(
      key: Key.parse(token.substring(0, separatorIndex)),
      duration: duration,
    );
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
    _notationSystemNotifier.dispose();
    _displayOptionsNotifier.dispose();
    super.dispose();
  }

  Future<void> _showSettingsModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ValueListenableBuilder(
          valueListenable: _notationSystemNotifier,
          builder: (context, notationSystem, _) {
            return ValueListenableBuilder(
              valueListenable: _displayOptionsNotifier,
              builder: (context, displayOptions, _) {
                return SettingsModal(
                  isDark: widget.themeMode == .dark,
                  notationSystem: notationSystem,
                  displayOptions: displayOptions,
                  onNotationSystemChanged: (notationSystem) {
                    _notationSystemNotifier.value = notationSystem;
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
      },
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
                  } on FormatException {
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
                    Listener(
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
                        animation: .merge([_modeAnimation, _timelineAnimation]),
                        builder: (context, _) {
                          return ValueListenableBuilder<
                            StringNotationSystem<Key>
                          >(
                            valueListenable: _notationSystemNotifier,
                            builder: (context, notationSystem, _) {
                              return ValueListenableBuilder(
                                valueListenable: _displayOptionsNotifier,
                                builder: (context, displayOptions, _) {
                                  return CircleOfFifthsPainter(
                                    vectors: _sequence.vectors,
                                    timelineKeys: _sequence.keys,
                                    visualizationMode: _visualizationMode,
                                    depthProgress: _modeAnimation.value,
                                    timelineProgress: _timelineAnimation.value,
                                    viewPan: _viewPan,
                                    rotationX: _rotationX,
                                    rotationY: _rotationY,
                                    notationSystem: notationSystem,
                                    displayOptions: displayOptions,
                                  );
                                },
                              );
                            },
                          );
                        },
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
                              onPressed: _showSettingsModal,
                              icon: const Icon(Icons.settings_outlined),
                              tooltip: 'Settings',
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
