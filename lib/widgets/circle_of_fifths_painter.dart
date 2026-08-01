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
    _drawKeyAnchors(canvas, center, outerRadius, innerRadius);
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

  void _drawKeyAnchors(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
  ) {
    final majorPaint = Paint()
      ..style = .fill
      ..color = const Color(0xfffffcf5);
    final majorStroke = Paint()
      ..style = .stroke
      ..strokeWidth = 2
      ..color = const Color(0xff575148);
    final minorPaint = Paint()
      ..style = .fill
      ..color = const Color(0xfffffcf5);
    final minorStroke = Paint()
      ..style = .stroke
      ..strokeWidth = 1.75
      ..color = const Color(0xff8a6d98);

    for (final note in majorNotes) {
      final angle = _angleFor(note);
      final majorAnchor = center + _unit(angle) * outerRadius;
      final minorAnchor = center + _unit(angle) * innerRadius;

      canvas
        ..drawCircle(majorAnchor, _majorAnchorRadius, majorPaint)
        ..drawCircle(majorAnchor, _majorAnchorRadius, majorStroke)
        ..drawCircle(minorAnchor, _minorAnchorRadius, minorPaint)
        ..drawCircle(minorAnchor, _minorAnchorRadius, minorStroke);
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
        majorKey.format(const GermanKeyNotation()),
        center + _unit(angle) * outerLabelRadius,
        const TextStyle(
          color: Color(0xff222826),
          fontSize: 15,
          fontWeight: .w700,
        ),
        backgroundColor: const Color(0xf2fffcf5),
      );
      _drawText(
        canvas,
        minorKey.format(const GermanKeyNotation()),
        center + _unit(angle) * innerLabelRadius,
        const TextStyle(
          color: Color(0xff6a4c7b),
          fontSize: 13,
          fontWeight: .w600,
        ),
        backgroundColor: const Color(0xf2fffcf5),
      );
    }
  }

  void _drawVectors(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
  ) {
    final paths = [
      for (final (index, vector) in vectors.indexed)
        _vectorPathFor(
          vector,
          index,
          center,
          outerRadius,
          innerRadius,
        ),
    ];

    for (final vectorPath in paths) {
      final vector = vectorPath.vector;
      final paint = Paint()
        ..style = .stroke
        ..strokeWidth = 3
        ..strokeCap = .round
        ..color = vector.color;

      if (vector.dashed) {
        _drawDashedPath(canvas, vectorPath.path, paint);
      } else {
        canvas.drawPath(vectorPath.path, paint);
      }

      _drawArrowHead(canvas, vectorPath);
    }

    for (final vectorPath in paths) {
      _drawVectorLabel(
        canvas,
        vectorPath.vector.label,
        vectorPath.labelPosition,
        vectorPath.vector.color,
      );
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
    final radius = key.mode == .major ? outerRadius : innerRadius;

    return center + _unit(angle) * radius;
  }

  _VectorPath _vectorPathFor(
    ModulationVector vector,
    int index,
    Offset center,
    double outerRadius,
    double innerRadius,
  ) {
    final startAnchor = _pointForKey(
      vector.from,
      center,
      outerRadius,
      innerRadius,
    );
    final endAnchor = _pointForKey(vector.to, center, outerRadius, innerRadius);
    final anchorDelta = endAnchor - startAnchor;
    final unitDelta = _normalized(anchorDelta);
    final startRadius = _anchorRadiusFor(vector.from);
    final endRadius = _anchorRadiusFor(vector.to);
    final start = startAnchor + unitDelta * (startRadius + 3);
    final tip = endAnchor - unitDelta * (endRadius + 7);
    final terminalDirection = _normalized(tip - start);
    final shaftEnd = tip - terminalDirection * _arrowLength * 0.72;
    final end = shaftEnd;
    final chord = end - start;
    final curveSide = vector.dashed ? -1.0 : 1.0;
    final modeLane = vector.from.mode == vector.to.mode ? 0.18 : 0.34;
    final lane = (modeLane + index * 0.035) * curveSide;
    final routeControl =
        Offset.lerp(start, tip, 0.5)! +
        _perpendicular(chord) * outerRadius * lane;
    final startControl = Offset.lerp(start, routeControl, 0.66)!;
    final endControl =
        end - terminalDirection * math.max(chord.distance * 0.24, 24);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        startControl.dx,
        startControl.dy,
        endControl.dx,
        endControl.dy,
        end.dx,
        end.dy,
      );
    final labelPosition = Offset.lerp(
      _cubicPoint(start, startControl, endControl, end, 0.5),
      routeControl,
      0.18,
    )!;

    return _VectorPath(
      vector: vector,
      path: path,
      labelPosition: labelPosition,
      tip: tip,
      terminalDirection: terminalDirection,
    );
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
          fontSize: 12,
          fontWeight: .w700,
        ),
      ),
      textAlign: .center,
      textDirection: .ltr,
    )..layout(maxWidth: 132);
    final rect = Rect.fromCenter(
      center: position,
      width: labelPainter.width + 14,
      height: labelPainter.height + 8,
    );
    final background = Paint()..color = const Color(0xeafffcf5);
    final border = Paint()
      ..style = .stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.42);

    canvas
      ..drawRRect(
        .fromRectAndRadius(rect, const .circular(6)),
        background,
      )
      ..drawRRect(
        .fromRectAndRadius(rect, const .circular(6)),
        border,
      );
    labelPainter.paint(
      canvas,
      rect.center - Offset(labelPainter.width / 2, labelPainter.height / 2),
    );
  }

  void _drawArrowHead(Canvas canvas, _VectorPath vectorPath) {
    final direction = vectorPath.terminalDirection;
    if (direction == .zero) return;

    final normal = _perpendicular(direction);
    final tip = vectorPath.tip;
    final baseCenter = tip - direction * _arrowLength;
    final left = baseCenter + normal * _arrowHalfWidth;
    final right = baseCenter - normal * _arrowHalfWidth;
    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..style = .fill
        ..color = vectorPath.vector.color,
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
    TextStyle style, {
    Color? backgroundColor,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: .center,
      textDirection: .ltr,
    )..layout(maxWidth: 120);
    final offset = center - Offset(painter.width / 2, painter.height / 2);

    if (backgroundColor != null) {
      final rect = Rect.fromLTWH(
        offset.dx - 5,
        offset.dy - 3,
        painter.width + 10,
        painter.height + 6,
      );
      canvas.drawRRect(
        .fromRectAndRadius(rect, const .circular(5)),
        Paint()..color = backgroundColor,
      );
    }

    painter.paint(canvas, offset);
  }

  double _angleFor(Note note) =>
      (note.circleOfFifthsDistance * math.pi / 6) - math.pi / 2;

  Offset _unit(double angle) => Offset(math.cos(angle), math.sin(angle));

  Offset _perpendicular(Offset offset) {
    final length = offset.distance;
    if (length == 0) return .zero;

    return Offset(-offset.dy / length, offset.dx / length);
  }

  Offset _normalized(Offset offset) {
    final length = offset.distance;
    if (length == 0) return .zero;

    return offset / length;
  }

  Offset _cubicPoint(
    Offset start,
    Offset control1,
    Offset control2,
    Offset end,
    double t,
  ) {
    final inverse = 1 - t;

    return start * inverse * inverse * inverse +
        control1 * 3 * inverse * inverse * t +
        control2 * 3 * inverse * t * t +
        end * t * t * t;
  }

  double _anchorRadiusFor(Key key) =>
      key.mode == .major ? _majorAnchorRadius : _minorAnchorRadius;

  @override
  bool shouldRepaint(_CircleOfFifthsCustomPainter oldDelegate) =>
      oldDelegate.vectors != vectors;
}

class _VectorPath {
  const _VectorPath({
    required this.vector,
    required this.path,
    required this.labelPosition,
    required this.tip,
    required this.terminalDirection,
  });

  final ModulationVector vector;
  final Path path;
  final Offset labelPosition;
  final Offset tip;
  final Offset terminalDirection;
}

const _arrowLength = 14.0;
const _arrowHalfWidth = 6.0;
const _majorAnchorRadius = 6.5;
const _minorAnchorRadius = 5.25;
