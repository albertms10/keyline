import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Interval, Key;
import 'package:keyline/model/modulation_vector.dart';
import 'package:keyline/widgets/circle_of_fifths_painter.dart';
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

  Future<void> _showSettingsModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isDark = widget.themeMode == .dark;

        return SafeArea(
          child: Padding(
            padding: const .fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Switch between light and dark modes.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Dark mode'),
                  value: isDark,
                  onChanged: (value) {
                    widget.onThemeModeChanged(value ? .dark : .light);
                    Navigator.of(sheetContext).pop();
                  },
                  contentPadding: const EdgeInsetsDirectional.only(
                    start: 16,
                    end: 2,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: .all(.circular(36)),
                  ),
                ),
              ],
            ),
          ),
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
                            Tooltip(
                              message: 'Toggle 3D mode',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.view_in_ar_outlined,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('3D'),
                                  const SizedBox(width: 6),
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
                                    materialTapTargetSize: .shrinkWrap,
                                  ),
                                ],
                              ),
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
