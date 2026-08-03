import 'package:flutter/material.dart' hide Key;
import 'package:keyline/widgets/circle_of_fifths_painter.dart';
import 'package:music_notes/music_notes.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({
    required this.isDark,
    required this.notationChoice,
    required this.displayOptions,
    this.onThemeModeChanged,
    this.onNotationChoiceChanged,
    this.onDisplayOptionsChanged,
    super.key,
  });

  final bool isDark;
  final KeyNotationChoice notationChoice;
  final VisualizationDisplayOptions displayOptions;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final ValueChanged<KeyNotationChoice>? onNotationChoiceChanged;
  final ValueChanged<VisualizationDisplayOptions>? onDisplayOptionsChanged;

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  late bool _isDark = widget.isDark;
  late KeyNotationChoice _notationChoice = widget.notationChoice;
  late VisualizationDisplayOptions _displayOptions = widget.displayOptions;

  @override
  void didUpdateWidget(SettingsModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isDark = widget.isDark;
    _notationChoice = widget.notationChoice;
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
      child: SingleChildScrollView(
        padding: const .fromLTRB(20, 20, 20, 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Appearance',
                child: SwitchListTile(
                  title: const Text('Dark mode'),
                  value: _isDark,
                  onChanged: (value) {
                    setState(() {
                      _isDark = value;
                    });
                    widget.onThemeModeChanged?.call(value ? .dark : .light);
                  },
                  contentPadding: const EdgeInsetsDirectional.only(
                    start: 12,
                    end: 2,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: .all(.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Notation',
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SegmentedButton<KeyNotationChoice>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: KeyNotationChoice.english,
                        label: Text('English'),
                      ),
                      ButtonSegment(
                        value: KeyNotationChoice.german,
                        label: Text('German'),
                      ),
                      ButtonSegment(
                        value: KeyNotationChoice.romance,
                        label: Text('Romance'),
                      ),
                    ],
                    selected: {_notationChoice},
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) return;
                      final choice = selection.first;
                      setState(() {
                        _notationChoice = choice;
                      });
                      widget.onNotationChoiceChanged?.call(choice);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Key labels',
                child: _OptionGrid(
                  children: [
                    _DisplayOptionTile(
                      icon: Icons.radio_button_checked,
                      title: 'Axis keys',
                      subtitle: 'Major and minor tonality labels',
                      value: _displayOptions.showAxisKeyLabels,
                      onChanged: (value) {
                        _setDisplayOptions(
                          _displayOptions.copyWith(showAxisKeyLabels: value),
                        );
                      },
                    ),
                    _DisplayOptionTile(
                      icon: Icons.label_outline,
                      title: 'Edge keys',
                      subtitle: 'Key labels on modulation endpoints',
                      value: _displayOptions.showEdgeKeyLabels,
                      onChanged: (value) {
                        _setDisplayOptions(
                          _displayOptions.copyWith(showEdgeKeyLabels: value),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Modulations',
                child: _OptionGrid(
                  children: [
                    _DisplayOptionTile(
                      icon: Icons.turn_slight_right,
                      title: 'Interval labels',
                      subtitle: 'Interval text on arrows',
                      value: _displayOptions.showVectorLabels,
                      onChanged: (value) {
                        _setDisplayOptions(
                          _displayOptions.copyWith(showVectorLabels: value),
                        );
                      },
                    ),
                    _DisplayOptionTile(
                      icon: Icons.timer_outlined,
                      title: 'Duration labels',
                      subtitle: 'Hold lengths in timeline',
                      value: _displayOptions.showDurationLabels,
                      onChanged: (value) {
                        _setDisplayOptions(
                          _displayOptions.copyWith(showDurationLabels: value),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Structure',
                child: _OptionGrid(
                  children: [
                    _DisplayOptionTile(
                      icon: Icons.grid_4x4,
                      title: 'Grid and spokes',
                      subtitle: 'Guide lines and scaffold',
                      value: _displayOptions.showGrid,
                      onChanged: (value) {
                        _setDisplayOptions(
                          _displayOptions.copyWith(showGrid: value),
                        );
                      },
                    ),
                    _DisplayOptionTile(
                      icon: Icons.legend_toggle,
                      title: 'Legend',
                      subtitle: 'Color key and helpers',
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
            ],
          ),
        ),
      ),
    );
  }
}

enum KeyNotationChoice {
  english,
  german,
  romance;

  StringNotationSystem<Key> get notationSystem {
    return switch (this) {
      english => const EnglishKeyNotation.symbol(),
      german => const GermanKeyNotation(),
      romance => const RomanceKeyNotation.symbol(),
    };
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        final spacing = columns == 1 ? 8.0 : 10.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: [
            for (final child in children)
              SizedBox(
                width: tileWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _DisplayOptionTile extends StatelessWidget {
  const _DisplayOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: const .all(.circular(8)),
      onTap: () {
        onChanged(!value);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const .all(.circular(8)),
          border: Border.all(
            color: value
                ? colorScheme.primary.withValues(alpha: 0.48)
                : colorScheme.outlineVariant,
          ),
          color: value
              ? colorScheme.primaryContainer.withValues(alpha: 0.34)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        ),
        child: Padding(
          padding: const .symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: value ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisSize: .min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: .w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: .ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: value,
                onChanged: (value) {
                  if (value == null) return;
                  onChanged(value);
                },
                visualDensity: .compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
