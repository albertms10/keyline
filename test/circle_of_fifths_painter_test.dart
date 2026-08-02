import 'package:flutter_test/flutter_test.dart';
import 'package:keyline/widgets/circle_of_fifths_painter.dart';
import 'package:keyline/widgets/screenshot_utils.dart';

void main() {
  group('compute3dVectorElevation', () {
    test('increases with longer durations', () {
      final shortDuration = compute3dVectorElevation(
        duration: 1,
        maxDuration: 3,
        index: 0,
      );
      final longDuration = compute3dVectorElevation(
        duration: 3,
        maxDuration: 3,
        index: 0,
      );

      expect(longDuration, greaterThan(shortDuration));
    });

    test('keeps a small index-based offset', () {
      final first = compute3dVectorElevation(
        duration: 1,
        maxDuration: 3,
        index: 0,
      );
      final second = compute3dVectorElevation(
        duration: 1,
        maxDuration: 3,
        index: 1,
      );

      expect(second, greaterThan(first));
    });
  });

  test('builds a safe capture filename', () {
    final timestamp = DateTime.utc(2026, 8, 3, 12, 34, 56, 789);

    expect(
      buildCaptureFilename(timestamp),
      'keyline-chart-2026-08-03T12-34-56-789Z.png',
    );
  });
}
