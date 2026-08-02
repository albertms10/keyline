import 'dart:math' as math;

import 'package:flutter/material.dart' hide Interval, Key;
import 'package:keyline/colors.dart';
import 'package:keyline/model.dart';
import 'package:music_notes/music_notes.dart' hide Size;

/// Draws a two-ring circle-of-fifths chart with modulation arrows.
class CircleOfFifthsPainter extends StatelessWidget {
  /// Creates a circle-of-fifths painter widget.
  const CircleOfFifthsPainter({
    required this.vectors,
    this.depthProgress = 0,
    this.rotationX = 0,
    this.rotationY = 0,
    this.viewPan = .zero,
    super.key,
  });

  /// Modulation vectors to overlay on the chart.
  final List<ModulationVector> vectors;

  /// Progress of the transition from flat paper to elevated 3D mode.
  final double depthProgress;

  /// X-axis rotation for the elevated view.
  final double rotationX;

  /// Y-axis rotation for the elevated view.
  final double rotationY;

  /// Pan offset for the elevated view.
  final Offset viewPan;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CircleOfFifthsCustomPainter(
        vectors: vectors,
        depthProgress: depthProgress,
        rotationX: rotationX,
        rotationY: rotationY,
        viewPan: viewPan,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CircleOfFifthsCustomPainter extends CustomPainter {
  const _CircleOfFifthsCustomPainter({
    required this.vectors,
    required this.depthProgress,
    required this.rotationX,
    required this.rotationY,
    required this.viewPan,
  });

  final List<ModulationVector> vectors;
  final double depthProgress;
  final double rotationX;
  final double rotationY;
  final Offset viewPan;

  static final List<Note> majorRingNotes = _majorRingNotes();

  static List<Note> _majorRingNotes() {
    final byPitchClass = <PitchClass, Note>{};

    for (final note in Note.c.circleOfFifths()) {
      byPitchClass.putIfAbsent(note.toClass(), () => note);
    }

    return byPitchClass.values.toList(growable: false);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final chartRadius = math.min(size.width, size.height) * 0.35;
    final outerRadius = chartRadius;
    final innerRadius = chartRadius * 0.62;
    final labelRadius = chartRadius * 1.13;

    if (depthProgress <= 0.001) {
      _drawRings(canvas, center, outerRadius, innerRadius);
      _drawSpokes(canvas, center, outerRadius);
      _drawKeyAnchors(canvas, center, outerRadius, innerRadius);
      _drawLabels(canvas, center, labelRadius, innerRadius);
      _drawVectors(canvas, center, outerRadius, innerRadius);
    } else {
      final projection = _Projection(
        center: center,
        size: size,
        progress: depthProgress,
        rotationX: rotationX,
        rotationY: rotationY,
        pan: viewPan,
      );

      _drawPaperPlane(
        canvas,
        projection,
        center,
        outerRadius,
        innerRadius,
        labelRadius,
      );
      _drawVectors3d(canvas, projection, center, outerRadius, innerRadius);
    }

    _drawLegend(canvas, size);
  }

  void _drawPaperPlane(
    Canvas canvas,
    _Projection projection,
    Offset center,
    double outerRadius,
    double innerRadius,
    double labelRadius,
  ) {
    final surfacePaint = Paint()
      ..style = .fill
      ..color = .lerp(
        const Color(0x00fffcf5),
        const Color(0x56fffcf5),
        depthProgress,
      )!;
    final surfacePath = _projectCirclePath(projection, center, outerRadius, 0);

    canvas.drawPath(surfacePath, surfacePaint);

    _drawProjectedCircle(
      canvas,
      projection,
      center,
      outerRadius,
      Paint()
        ..style = .stroke
        ..strokeWidth = 2
        ..color = const Color(0xff7d786c),
    );
    _drawProjectedCircle(
      canvas,
      projection,
      center,
      innerRadius,
      Paint()
        ..style = .stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xffb9ad96),
    );

    final spokePaint = Paint()
      ..style = .stroke
      ..strokeWidth = 1
      ..color = const Color(0xffdfd7c7);
    for (final note in majorRingNotes) {
      final angle = _angleFor(note);
      canvas.drawLine(
        projection.project(center, 0),
        projection.project(center + _unit(angle) * outerRadius, 0),
        spokePaint,
      );
    }

    _drawProjectedKeyAnchors(
      canvas,
      projection,
      center,
      outerRadius,
      innerRadius,
    );
    _drawProjectedLabels(canvas, projection, center, labelRadius, innerRadius);
  }

  void _drawProjectedCircle(
    Canvas canvas,
    _Projection projection,
    Offset center,
    double radius,
    Paint paint,
  ) {
    canvas.drawPath(_projectCirclePath(projection, center, radius, 0), paint);
  }

  Path _projectCirclePath(
    _Projection projection,
    Offset center,
    double radius,
    double z,
  ) {
    final path = Path();
    const segments = 96;
    for (var i = 0; i <= segments; i++) {
      final angle = math.pi * 2 * i / segments;
      final point = projection.project(center + _unit(angle) * radius, z);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    return path;
  }

  void _drawProjectedKeyAnchors(
    Canvas canvas,
    _Projection projection,
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

    for (final note in majorRingNotes) {
      final angle = _angleFor(note);
      final majorAnchor = projection.project(
        center + _unit(angle) * outerRadius,
        0,
      );
      final minorAnchor = projection.project(
        center + _unit(angle) * innerRadius,
        0,
      );

      canvas
        ..drawCircle(majorAnchor, _majorAnchorRadius, majorPaint)
        ..drawCircle(majorAnchor, _majorAnchorRadius, majorStroke)
        ..drawCircle(minorAnchor, _minorAnchorRadius, minorPaint)
        ..drawCircle(minorAnchor, _minorAnchorRadius, minorStroke);
    }
  }

  void _drawProjectedLabels(
    Canvas canvas,
    _Projection projection,
    Offset center,
    double outerLabelRadius,
    double innerLabelRadius,
  ) {
    for (final note in majorRingNotes) {
      final majorKey = note.major.signature.keys[TonalMode.major]!;
      final minorKey = majorKey.signature.keys[TonalMode.minor]!;
      final angle = _angleFor(note);

      _drawText(
        canvas,
        majorKey.format(const GermanKeyNotation()),
        projection.project(center + _unit(angle) * outerLabelRadius, 0),
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
        projection.project(center + _unit(angle) * innerLabelRadius, 0),
        const TextStyle(
          color: Color(0xff6a4c7b),
          fontSize: 13,
          fontWeight: .w600,
        ),
        backgroundColor: const Color(0xf2fffcf5),
      );
    }
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

    for (final note in majorRingNotes) {
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

    for (final note in majorRingNotes) {
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
    for (final note in majorRingNotes) {
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

  void _drawVectors3d(
    Canvas canvas,
    _Projection projection,
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

    for (final (index, vectorPath) in paths.indexed) {
      final elevation = _elevationFor(index);
      final shadowPath = _projectVectorPath(projection, vectorPath, 0);
      final shadowPaint = Paint()
        ..style = .stroke
        ..strokeWidth = 4
        ..strokeCap = .round
        ..color = const Color(0xff3c3a35).withValues(
          alpha: 0.07 + depthProgress * 0.06,
        );

      if (vectorPath.vector.dashed) {
        _drawDashedPath(canvas, shadowPath, shadowPaint);
      } else {
        canvas.drawPath(shadowPath, shadowPaint);
      }

      _drawRiser(canvas, projection, vectorPath.start, elevation);
      _drawRiser(canvas, projection, vectorPath.tip, elevation);
    }

    for (final (index, vectorPath) in paths.indexed) {
      final vector = vectorPath.vector;
      final elevation = _elevationFor(index);
      final path = _projectVectorPath(projection, vectorPath, elevation);
      final paint = Paint()
        ..style = .stroke
        ..strokeWidth = 3.6
        ..strokeCap = .round
        ..color = vector.color;

      if (vector.dashed) {
        _drawDashedPath(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }

      _drawArrowHead3d(canvas, projection, vectorPath, elevation);
    }

    for (final (index, vectorPath) in paths.indexed) {
      _drawVectorLabel(
        canvas,
        vectorPath.vector.label,
        projection.project(vectorPath.labelPosition, _elevationFor(index)),
        vectorPath.vector.color,
      );
    }
  }

  Path _projectVectorPath(
    _Projection projection,
    _VectorPath vectorPath,
    double z,
  ) {
    final start = projection.project(vectorPath.start, z);
    final startControl = projection.project(vectorPath.startControl, z);
    final endControl = projection.project(vectorPath.endControl, z);
    final end = projection.project(vectorPath.end, z);

    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        startControl.dx,
        startControl.dy,
        endControl.dx,
        endControl.dy,
        end.dx,
        end.dy,
      );
  }

  void _drawRiser(
    Canvas canvas,
    _Projection projection,
    Offset point,
    double elevation,
  ) {
    final bottom = projection.project(point, 0);
    final top = projection.project(point, elevation);
    final paint = Paint()
      ..style = .stroke
      ..strokeWidth = 1.2
      ..strokeCap = .round
      ..color = const Color(0xff8c8373).withValues(
        alpha: 0.16 * depthProgress,
      );

    canvas.drawLine(bottom, top, paint);
  }

  void _drawArrowHead3d(
    Canvas canvas,
    _Projection projection,
    _VectorPath vectorPath,
    double elevation,
  ) {
    final tip = projection.project(vectorPath.tip, elevation);
    final shaftPoint = projection.project(
      vectorPath.tip - vectorPath.terminalDirection * _arrowLength,
      elevation,
    );
    final direction = _normalized(tip - shaftPoint);
    if (direction == .zero) return;

    final normal = _perpendicular(direction);
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

  void _drawLegend(Canvas canvas, Size size) {
    const origin = Offset(18, 18);
    const textStyle = TextStyle(
      color: Color(0xff3c3a35),
      fontSize: 12,
      fontWeight: .w600,
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
      start: start,
      startControl: startControl,
      endControl: endControl,
      end: end,
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

  double _elevationFor(int index) => 30 + index * 22;

  @override
  bool shouldRepaint(_CircleOfFifthsCustomPainter oldDelegate) =>
      oldDelegate.vectors != vectors ||
      oldDelegate.depthProgress != depthProgress ||
      oldDelegate.rotationX != rotationX ||
      oldDelegate.rotationY != rotationY ||
      oldDelegate.viewPan != viewPan;
}

class _VectorPath {
  const _VectorPath({
    required this.vector,
    required this.path,
    required this.start,
    required this.startControl,
    required this.endControl,
    required this.end,
    required this.labelPosition,
    required this.tip,
    required this.terminalDirection,
  });

  final ModulationVector vector;
  final Path path;
  final Offset start;
  final Offset startControl;
  final Offset endControl;
  final Offset end;
  final Offset labelPosition;
  final Offset tip;
  final Offset terminalDirection;
}

class _Projection {
  const _Projection({
    required this.center,
    required this.size,
    required this.progress,
    required this.rotationX,
    required this.rotationY,
    required this.pan,
  });

  final Offset center;
  final Size size;
  final double progress;
  final double rotationX;
  final double rotationY;
  final Offset pan;

  Offset project(Offset point, double z) {
    final local = point - center;
    final elevatedZ = z * progress;
    final xRotation = rotationX * progress;
    final yRotation = rotationY * progress;
    final cosX = math.cos(xRotation);
    final sinX = math.sin(xRotation);
    final cosY = math.cos(yRotation);
    final sinY = math.sin(yRotation);

    final x1 = local.dx * cosY + elevatedZ * sinY;
    final z1 = -local.dx * sinY + elevatedZ * cosY;
    final y2 = local.dy * cosX - z1 * sinX;
    final z2 = local.dy * sinX + z1 * cosX;
    final focalLength = math.max(size.width, size.height) * 1.85;
    final perspective = focalLength / math.max(160, focalLength - z2);

    return center + Offset(x1 * perspective, y2 * perspective) + pan * progress;
  }
}

const _arrowLength = 14.0;
const _arrowHalfWidth = 6.0;
const _majorAnchorRadius = 6.5;
const _minorAnchorRadius = 5.25;
