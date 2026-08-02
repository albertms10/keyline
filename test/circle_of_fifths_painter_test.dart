import 'package:flutter_test/flutter_test.dart';
import 'package:keyline/widgets/circle_of_fifths_painter.dart';

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
}
