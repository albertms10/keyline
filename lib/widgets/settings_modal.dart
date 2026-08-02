import 'package:flutter/material.dart' hide Key;
import 'package:keyline/widgets/circle_of_fifths_painter.dart';
import 'package:music_notes/music_notes.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({
    required this.isDark,
    required this.notationSystem,
    required this.displayOptions,
    this.onThemeModeChanged,
    this.onNotationSystemChanged,
    this.onDisplayOptionsChanged,
    super.key,
  });

  final bool isDark;
  final StringNotationSystem<Key> notationSystem;
  final VisualizationDisplayOptions displayOptions;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final ValueChanged<StringNotationSystem<Key>>? onNotationSystemChanged;
  final ValueChanged<VisualizationDisplayOptions>? onDisplayOptionsChanged;

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  late bool _isDark = widget.isDark;
  late StringNotationSystem<Key> _notationSystem = widget.notationSystem;
  late VisualizationDisplayOptions _displayOptions = widget.displayOptions;

  @override
  void didUpdateWidget(SettingsModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isDark = widget.isDark;
    _notationSystem = widget.notationSystem;
    _displayOptions = widget.displayOptions;
  }

  void _setDisplayOptions(VisualizationDisplayOptions options) {
    setState(() {
      _displayOptions = options;
    });
    widget.onDisplayOptionsChanged?.call(options);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const .fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Switch between light and dark modes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Dark mode'),
              value: _isDark,
              onChanged: (value) {
                setState(() {
                  _isDark = value;
                });
                widget.onThemeModeChanged?.call(value ? .dark : .light);
              },
              contentPadding: const EdgeInsetsDirectional.only(
                start: 16,
                end: 2,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: .all(.circular(36)),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Key notation'),
              trailing: SegmentedButton<StringNotationSystem<Key>>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: EnglishKeyNotation.symbol(),
                    label: Text('English'),
                  ),
                  ButtonSegment(
                    value: GermanKeyNotation(),
                    label: Text('German'),
                  ),
                  ButtonSegment(
                    value: RomanceKeyNotation.symbol(),
                    label: Text('Romance'),
                  ),
                ],
                selected: {_notationSystem},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) return;
                  setState(() {
                    _notationSystem = selection.first;
                  });
                  widget.onNotationSystemChanged?.call(selection.first);
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Display',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _DisplaySwitch(
              title: 'Major tonalities',
              value: _displayOptions.showMajorLabels,
              onChanged: (value) {
                _setDisplayOptions(
                  _displayOptions.copyWith(showMajorLabels: value),
                );
              },
            ),
            _DisplaySwitch(
              title: 'Minor tonalities',
              value: _displayOptions.showMinorLabels,
              onChanged: (value) {
                _setDisplayOptions(
                  _displayOptions.copyWith(showMinorLabels: value),
                );
              },
            ),
            _DisplaySwitch(
              title: 'Vector labels',
              value: _displayOptions.showVectorLabels,
              onChanged: (value) {
                _setDisplayOptions(
                  _displayOptions.copyWith(showVectorLabels: value),
                );
              },
            ),
            _DisplaySwitch(
              title: 'Duration labels',
              value: _displayOptions.showDurationLabels,
              onChanged: (value) {
                _setDisplayOptions(
                  _displayOptions.copyWith(showDurationLabels: value),
                );
              },
            ),
            _DisplaySwitch(
              title: 'Grid and spokes',
              value: _displayOptions.showGrid,
              onChanged: (value) {
                _setDisplayOptions(_displayOptions.copyWith(showGrid: value));
              },
            ),
            _DisplaySwitch(
              title: 'Legend',
              value: _displayOptions.showLegend,
              onChanged: (value) {
                _setDisplayOptions(
                  _displayOptions.copyWith(showLegend: value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DisplaySwitch extends StatelessWidget {
  const _DisplaySwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsetsDirectional.only(
        start: 16,
        end: 2,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: .all(.circular(36)),
      ),
    );
  }
}
