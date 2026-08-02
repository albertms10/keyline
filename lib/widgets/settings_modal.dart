import 'package:flutter/material.dart' hide Key;
import 'package:music_notes/music_notes.dart';

class SettingsModal extends StatelessWidget {
  const SettingsModal({
    required this.isDark,
    required this.notationSystem,
    this.onThemeModeChanged,
    this.onNotationSystemChanged,
    super.key,
  });

  final bool isDark;
  final StringNotationSystem<Key> notationSystem;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final ValueChanged<StringNotationSystem<Key>>? onNotationSystemChanged;

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
              value: isDark,
              onChanged: (value) {
                onThemeModeChanged?.call(value ? .dark : .light);
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
                selected: {notationSystem},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) return;
                  onNotationSystemChanged?.call(selection.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
