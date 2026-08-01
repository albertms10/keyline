import 'dart:math' as math;

import 'package:flutter/material.dart' hide Interval, Key;
import 'package:keyline/colors.dart';
import 'package:keyline/model.dart';
import 'package:keyline/utils/music.dart';
import 'package:music_notes/music_notes.dart' hide Size;

/// Draws a two-ring circle-of-fifths chart with modulation arrows.
class CircleOfFifthsPainter extends StatelessWidget {
  /// Creates a circle-of-fifths painter widget.
  const CircleOfFifthsPainter({required this.vectors, super.key});

  /// Modulation vectors to overlay on the chart.
  final List<ModulationVector> vectors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CircleOfFifthsCustomPainter(vectors),
      child: const SizedBox.expand(),
    );
  }
}

class _CircleOfFifthsCustomPainter extends CustomPainter {
  _CircleOfFifthsCustomPainter(this.vectors);

  final List<ModulationVector> vectors;
  final List<Note> majorNotes = majorRingNotes();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final chartRadius = math.min(size.width, size.height) * 0.35;
    final outerRadius = chartRadius;
    final innerRadius = chartRadius * 0.62;
    final labelRadius = chartRadius * 1.13;

    _drawRings(canvas, center, outerRadius, innerRadius);
    _drawSpokes(canvas, center, outerRadius);
    _drawLabels(canvas, center, labelRadius, innerRadius);
    _drawVectors(canvas, center, outerRadius, innerRadius);
    _drawLegend(canvas, size);
  }

  void _drawRings(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
  ) {
    final ringPaint = Paint()
      ..style = .stroke
      ..strokeWidth = 2
      ..color = const Color(0xff7d786c);
    final innerPaint = Paint()
      ..style = .stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xffb9ad96);

    canvas
      ..drawCircle(center, outerRadius, ringPaint)
      ..drawCircle(center, innerRadius, innerPaint);
  }

  void _drawSpokes(Canvas canvas, Offset center, double radius) {
    final spokePaint = Paint()
      ..style = .stroke
      ..strokeWidth = 1
      ..color = const Color(0xffdfd7c7);

    for (final note in majorNotes) {
      final angle = _angleFor(note);
      canvas.drawLine(center, center + _unit(angle) * radius, spokePaint);
    }
  }

  void _drawLabels(
    Canvas canvas,
    Offset center,
    double outerLabelRadius,
    double innerLabelRadius,
  ) {
    for (final note in majorNotes) {
      final majorKey = note.major.signature.keys[TonalMode.major]!;
      final minorKey = majorKey.signature.keys[TonalMode.minor]!;
      final angle = _angleFor(note);

      _drawText(
        canvas,
        majorKey.format(),
        center + _unit(angle) * outerLabelRadius,
        const TextStyle(
          color: Color(0xff222826),
          fontSize: 16,
          fontWeight: .w700,
        ),
      );
      _drawText(
        canvas,
        minorKey.format(),
        center + _unit(angle) * innerLabelRadius,
        const TextStyle(
          color: Color(0xff6a4c7b),
          fontSize: 13,
          fontWeight: .w600,
        ),
      );
    }
  }

  void _drawVectors(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
  ) {
    for (final vector in vectors) {
      final start = _pointForKey(vector.from, center, outerRadius, innerRadius);
      final end = _pointForKey(vector.to, center, outerRadius, innerRadius);
      final sweep = vector.dashed ? -0.16 : 0.16;
      final control =
          Offset.lerp(start, end, 0.5)! +
          _perpendicular(end - start) * (outerRadius * sweep);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      final paint = Paint()
        ..style = .stroke
        ..strokeWidth = 3
        ..strokeCap = .round
        ..color = vector.color;

      if (vector.dashed) {
        _drawDashedPath(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }

      _drawArrowHead(canvas, path, vector.color);
      _drawVectorLabel(canvas, vector.label, control, vector.color);
    }
  }

  void _drawLegend(Canvas canvas, Size size) {
    const origin = Offset(18, 18);
    const textStyle = TextStyle(
      color: Color(0xff3c3a35),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    final upPaint = Paint()
      ..style = .stroke
      ..strokeWidth = 3
      ..strokeCap = .round
      ..color = majorToMinorColor;
    final downPaint = Paint()
      ..style = .stroke
      ..strokeWidth = 3
      ..strokeCap = .round
      ..color = minorToMajorColor;

    canvas.drawLine(origin, origin + const Offset(34, 0), upPaint);
    _drawText(
      canvas,
      'solid: up a fifth',
      origin + const Offset(104, 0),
      textStyle,
    );

    final dashedPath = Path()
      ..moveTo(origin.dx, origin.dy + 24)
      ..lineTo(origin.dx + 34, origin.dy + 24);
    _drawDashedPath(canvas, dashedPath, downPaint);
    _drawText(
      canvas,
      'dashed: down a fifth',
      origin + const Offset(112, 24),
      textStyle,
    );
  }

  Offset _pointForKey(
    Key key,
    Offset center,
    double outerRadius,
    double innerRadius,
  ) {
    final matchingMajor = key.mode == .major ? key : key.relative;
    final angle = _angleFor(matchingMajor.note);
    final radius = key.mode == .major ? outerRadius * 0.86 : innerRadius;

    return center + _unit(angle) * radius;
  }

  void _drawVectorLabel(
    Canvas canvas,
    String label,
    Offset position,
    Color color,
  ) {
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: .w700,
        ),
      ),
      textAlign: .center,
      textDirection: .ltr,
    )..layout(maxWidth: 96);
    final rect = Rect.fromCenter(
      center: position,
      width: labelPainter.width + 10,
      height: labelPainter.height + 6,
    );
    final background = Paint()..color = const Color(0xeafffcf5);

    canvas.drawRRect(
      .fromRectAndRadius(rect, const .circular(6)),
      background,
    );
    labelPainter.paint(
      canvas,
      rect.center - Offset(labelPainter.width / 2, labelPainter.height / 2),
    );
  }

  void _drawArrowHead(Canvas canvas, Path path, Color color) {
    final metric = path.computeMetrics().last;
    final tangent = metric.getTangentForOffset(metric.length * 0.98);
    if (tangent == null) return;

    const arrowLength = 13.0;
    const arrowAngle = math.pi / 7;
    final direction = tangent.angle;
    final point = tangent.position;
    final arrowPath = Path()
      ..moveTo(point.dx, point.dy)
      ..lineTo(
        point.dx - arrowLength * math.cos(direction - arrowAngle),
        point.dy - arrowLength * math.sin(direction - arrowAngle),
      )
      ..moveTo(point.dx, point.dy)
      ..lineTo(
        point.dx - arrowLength * math.cos(direction + arrowAngle),
        point.dy - arrowLength * math.sin(direction + arrowAngle),
      );

    canvas.drawPath(
      arrowPath,
      Paint()
        ..style = .stroke
        ..strokeWidth = 3
        ..strokeCap = .round
        ..color = color,
    );
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 9, metric.length)),
          paint,
        );
        distance += 15;
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: .center,
      textDirection: .ltr,
    )..layout(maxWidth: 120);

    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  double _angleFor(Note note) =>
      (note.circleOfFifthsDistance * math.pi / 6) - math.pi / 2;

  Offset _unit(double angle) => Offset(math.cos(angle), math.sin(angle));

  Offset _perpendicular(Offset offset) {
    final length = offset.distance;
    if (length == 0) return .zero;

    return Offset(-offset.dy / length, offset.dx / length);
  }

  @override
  bool shouldRepaint(_CircleOfFifthsCustomPainter oldDelegate) =>
      oldDelegate.vectors != vectors;
}
