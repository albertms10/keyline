import 'dart:math' as math;

import 'package:flutter/material.dart' hide Interval, Key;
import 'package:keyline/colors.dart';
import 'package:keyline/model.dart';
import 'package:music_notes/music_notes.dart' hide Size;
import 'package:music_notes/utils.dart';

/// Available visualization layouts.
enum VisualizationMode {
  /// The elevated circle-of-fifths chart.
  circle3d,

  /// The flat circle-of-fifths chart.
  circle2d,

  /// The unfolded circle-of-fifths timeline.
  timeline,
}

/// User-controlled display toggles for chart annotations.
class VisualizationDisplayOptions {
  /// Creates display options for optional chart annotations.
  const VisualizationDisplayOptions({
    this.showMajorLabels = true,
    this.showMinorLabels = true,
    this.showVectorLabels = true,
    this.showDurationLabels = true,
    this.showGrid = true,
    this.showLegend = true,
  });

  /// Whether major tonality labels are visible.
  final bool showMajorLabels;

  /// Whether minor tonality labels are visible.
  final bool showMinorLabels;

  /// Whether modulation interval labels are visible.
  final bool showVectorLabels;

  /// Whether timeline duration labels are visible.
  final bool showDurationLabels;

  /// Whether spokes/grid helper lines are visible.
  final bool showGrid;

  /// Whether the legend is visible.
  final bool showLegend;

  /// Returns a copy with selected fields replaced.
  VisualizationDisplayOptions copyWith({
    bool? showMajorLabels,
    bool? showMinorLabels,
    bool? showVectorLabels,
    bool? showDurationLabels,
    bool? showGrid,
    bool? showLegend,
  }) {
    return VisualizationDisplayOptions(
      showMajorLabels: showMajorLabels ?? this.showMajorLabels,
      showMinorLabels: showMinorLabels ?? this.showMinorLabels,
      showVectorLabels: showVectorLabels ?? this.showVectorLabels,
      showDurationLabels: showDurationLabels ?? this.showDurationLabels,
      showGrid: showGrid ?? this.showGrid,
      showLegend: showLegend ?? this.showLegend,
    );
  }
}

/// Draws a two-ring circle-of-fifths chart with modulation arrows.
class CircleOfFifthsPainter extends StatelessWidget {
  /// Creates a circle-of-fifths painter widget.
  const CircleOfFifthsPainter({
    required this.vectors,
    required this.timelineKeys,
    required this.visualizationMode,
    required this.displayOptions,
    this.depthProgress = 0,
    this.timelineProgress = 0,
    this.rotationX = 0,
    this.rotationY = 0,
    this.viewPan = .zero,
    this.notationSystem = const GermanKeyNotation(),
    super.key,
  });

  /// Modulation vectors to overlay on the chart.
  final List<ModulationVector> vectors;

  /// Timed tonal keys used by the timeline layout.
  final List<TimedKey> timelineKeys;

  /// The active visualization layout.
  final VisualizationMode visualizationMode;

  /// Display toggles for optional labels and guide lines.
  final VisualizationDisplayOptions displayOptions;

  /// Progress of the transition from flat paper to elevated 3D mode.
  final double depthProgress;

  /// Progress of the transition from circle to unfolded timeline.
  final double timelineProgress;

  /// X-axis rotation for the elevated view.
  final double rotationX;

  /// Y-axis rotation for the elevated view.
  final double rotationY;

  /// Pan offset for the elevated view.
  final Offset viewPan;

  /// The notation system used for [Key].
  final StringNotationSystem<Key> notationSystem;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<KeylineColors>() ?? .light;

    return Stack(
      children: [
        CustomPaint(
          painter: _CircleOfFifthsCustomPainter(
            vectors: vectors,
            timelineKeys: timelineKeys,
            visualizationMode: visualizationMode,
            displayOptions: displayOptions,
            depthProgress: depthProgress,
            timelineProgress: timelineProgress,
            rotationX: rotationX,
            rotationY: rotationY,
            viewPan: viewPan,
            palette: palette,
            notationSystem: notationSystem,
          ),
          child: const SizedBox.expand(),
        ),
        if (displayOptions.showLegend)
          Positioned(
            left: 12,
            top: 12,
            child: _VectorLegend(palette: palette),
          ),
      ],
    );
  }
}

class _CircleOfFifthsCustomPainter extends CustomPainter {
  const _CircleOfFifthsCustomPainter({
    required this.vectors,
    required this.timelineKeys,
    required this.visualizationMode,
    required this.displayOptions,
    required this.depthProgress,
    required this.timelineProgress,
    required this.rotationX,
    required this.rotationY,
    required this.viewPan,
    required this.palette,
    required this.notationSystem,
  });

  final List<ModulationVector> vectors;
  final List<TimedKey> timelineKeys;
  final VisualizationMode visualizationMode;
  final VisualizationDisplayOptions displayOptions;
  final double depthProgress;
  final double timelineProgress;
  final double rotationX;
  final double rotationY;
  final Offset viewPan;
  final KeylineColors palette;
  final StringNotationSystem<Key> notationSystem;

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

    if (timelineProgress > 0.001) {
      _drawTimeline(
        canvas,
        size,
        center,
        outerRadius,
        innerRadius,
        labelRadius,
        timelineProgress,
      );
      return;
    }

    if (depthProgress <= 0.001) {
      _drawRings(canvas, center, outerRadius, innerRadius);
      if (displayOptions.showGrid) {
        _drawSpokes(canvas, center, outerRadius);
      }
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
  }

  void _drawTimeline(
    Canvas canvas,
    Size size,
    Offset center,
    double outerRadius,
    double innerRadius,
    double labelRadius,
    double progress,
  ) {
    final entries = timelineKeys;
    if (entries.isEmpty) return;

    final double horizontalInset = math.min(96, size.width * 0.18);
    const topInset = 46.0;
    const bottomInset = 58.0;
    final chartLeft = horizontalInset;
    final chartRight = size.width - 34;
    const chartTop = topInset;
    final chartBottom = size.height - bottomInset;
    if (chartRight <= chartLeft || chartBottom <= chartTop) return;

    final distances = [
      for (final entry in entries) entry.key.signature.distance!,
      for (final note in majorRingNotes) note.major.signature.distance!,
    ];
    final minDistance = math.min(-6, distances.reduce(math.min));
    final maxDistance = math.max(6, distances.reduce(math.max));
    final distanceSpan = math.max(1, maxDistance - minDistance);
    final totalDuration = math.max(
      1,
      entries.fold<double>(0, (total, entry) => total + entry.duration),
    );

    double yForDistance(int distance) =>
        chartBottom -
        (distance - minDistance) / distanceSpan * (chartBottom - chartTop);
    double yForFifths(double distance) =>
        chartBottom -
        (distance - minDistance) / distanceSpan * (chartBottom - chartTop);
    double xForTime(double time) =>
        chartLeft + time / totalDuration * (chartRight - chartLeft);

    final gridProgress = ((progress - 0.38) / 0.62).clamp(0.0, 1.0);
    if (displayOptions.showGrid) {
      _drawTimelineGrid(
        canvas,
        chartLeft,
        chartRight,
        chartTop,
        chartBottom,
        minDistance,
        maxDistance,
        yForDistance,
        gridProgress,
      );
    }
    _drawUnfoldingFifthsScaffold(
      canvas,
      center,
      outerRadius,
      innerRadius,
      labelRadius,
      chartLeft,
      yForFifths,
      progress,
    );

    var currentTime = 0.0;
    final points = <_TimelinePoint>[];
    for (final entry in entries) {
      final circularPosition = _pointForKey(
        entry.key,
        center,
        outerRadius,
        innerRadius,
      );
      final timelinePosition = Offset(
        xForTime(currentTime),
        yForDistance(entry.key.signature.distance!),
      );
      points.add(
        _TimelinePoint(
          entry: entry,
          time: currentTime,
          position: Offset.lerp(circularPosition, timelinePosition, progress)!,
        ),
      );
      currentTime += entry.duration;
    }

    for (final point in points) {
      final circularEnd = _pointForKey(
        point.entry.key,
        center,
        outerRadius,
        innerRadius,
      );
      final timelineEnd = Offset(
        xForTime(point.time + point.entry.duration),
        yForDistance(point.entry.key.signature.distance!),
      );
      final holdEnd = Offset(
        Offset.lerp(circularEnd, timelineEnd, progress)!.dx,
        point.position.dy,
      );
      final holdPaint = Paint()
        ..style = .stroke
        ..strokeWidth = 4
        ..strokeCap = .round
        ..color = point.entry.key.mode == .major
            ? palette.majorToMajor.withValues(alpha: 0.5)
            : palette.minorToMinor.withValues(alpha: 0.5);
      canvas.drawLine(point.position, holdEnd, holdPaint);
    }

    for (final (index, vector) in vectors.indexed) {
      if (index + 1 >= points.length) break;

      final from = points[index];
      final to = points[index + 1];
      final circularPath = _vectorPathFor(
        vector,
        index,
        center,
        outerRadius,
        innerRadius,
      );
      final timelineStart = Offset(
        xForTime(from.time + from.entry.duration),
        yForDistance(from.entry.key.signature.distance!),
      );
      final timelineTip = Offset(timelineStart.dx, to.position.dy);
      final start = Offset.lerp(circularPath.start, timelineStart, progress)!;
      final timelineDirection = _normalized(timelineTip - timelineStart);
      final timelineEnd = timelineTip - timelineDirection * _arrowLength * 0.72;
      final end = Offset.lerp(circularPath.end, timelineEnd, progress)!;
      final tip = Offset.lerp(circularPath.tip, timelineTip, progress)!;
      final timelineDelta = timelineEnd - timelineStart;
      final startControl = Offset.lerp(
        circularPath.startControl,
        timelineStart + timelineDelta * 0.34,
        progress,
      )!;
      final endControl = Offset.lerp(
        circularPath.endControl,
        timelineStart + timelineDelta * 0.72,
        progress,
      )!;
      _drawTimelineVector(
        canvas,
        vector,
        start,
        startControl,
        endControl,
        end,
        tip,
      );
    }

    for (final point in points) {
      _drawTimelineKeyLabel(canvas, point, progress);
    }

    if (displayOptions.showGrid) {
      _drawTimelineAxisLabels(
        canvas,
        size,
        chartLeft,
        chartRight,
        chartBottom,
        gridProgress,
      );
    }
    if (displayOptions.showLegend) {
      _drawTimelineLegend(canvas, size, gridProgress);
    }
  }

  void _drawTimelineGrid(
    Canvas canvas,
    double chartLeft,
    double chartRight,
    double chartTop,
    double chartBottom,
    int minDistance,
    int maxDistance,
    double Function(int distance) yForDistance,
    double progress,
  ) {
    final axisPaint = Paint()
      ..style = .stroke
      ..strokeWidth = 1.6
      ..color = palette.chartRing.withValues(alpha: progress);
    final gridPaint = Paint()
      ..style = .stroke
      ..strokeWidth = 1
      ..color = palette.chartSpoke.withValues(alpha: 0.72 * progress);

    for (var distance = minDistance; distance <= maxDistance; distance++) {
      final y = yForDistance(distance);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      _drawText(
        canvas,
        distance == 0 ? 'C / 0' : distance.toDeltaString(),
        Offset(chartLeft - 36, y),
        TextStyle(
          color: (distance == 0 ? palette.primaryText : palette.legendText)
              .withValues(alpha: progress),
          fontSize: distance == 0 ? 13 : 12,
          fontWeight: distance == 0 ? .w700 : .w500,
        ),
      );
    }

    final zeroY = yForDistance(0);
    canvas
      ..drawLine(
        Offset(chartLeft, chartTop),
        Offset(chartLeft, chartBottom),
        axisPaint,
      )
      ..drawLine(Offset(chartLeft, zeroY), Offset(chartRight, zeroY), axisPaint)
      ..drawLine(
        Offset(chartLeft, chartBottom),
        Offset(chartRight, chartBottom),
        axisPaint,
      );
  }

  void _drawUnfoldingFifthsScaffold(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double labelRadius,
    double axisX,
    double Function(double distance) yForFifths,
    double progress,
  ) {
    final spokePaint = Paint()
      ..style = .stroke
      ..strokeWidth = 1
      ..color = palette.chartSpoke;
    final majorPaint = Paint()
      ..style = .stroke
      ..strokeWidth = 2
      ..color = palette.chartRing;
    final minorPaint = Paint()
      ..style = .stroke
      ..strokeWidth = 1.5
      ..color = palette.chartInnerRing;

    canvas
      ..drawPath(
        _morphedFifthsArcPath(
          center: center,
          radius: outerRadius,
          axisX: axisX,
          yForFifths: yForFifths,
          progress: progress,
          startDistance: 0,
          endDistance: 6,
        ),
        majorPaint,
      )
      ..drawPath(
        _morphedFifthsArcPath(
          center: center,
          radius: outerRadius,
          axisX: axisX,
          yForFifths: yForFifths,
          progress: progress,
          startDistance: 0,
          endDistance: -6,
        ),
        majorPaint,
      )
      ..drawPath(
        _morphedFifthsArcPath(
          center: center,
          radius: innerRadius,
          axisX: axisX + 18,
          yForFifths: yForFifths,
          progress: progress,
          startDistance: 0,
          endDistance: 6,
        ),
        minorPaint,
      )
      ..drawPath(
        _morphedFifthsArcPath(
          center: center,
          radius: innerRadius,
          axisX: axisX + 18,
          yForFifths: yForFifths,
          progress: progress,
          startDistance: 0,
          endDistance: -6,
        ),
        minorPaint,
      );

    for (final note in majorRingNotes) {
      final angle = _angleFor(note);
      final majorKey = note.major.signature.keys[TonalMode.major]!;
      final minorKey = majorKey.signature.keys[TonalMode.minor]!;
      final distance = majorKey.signature.distance!;
      final majorCircle = center + _unit(angle) * outerRadius;
      final minorCircle = center + _unit(angle) * innerRadius;
      final majorAxis = Offset(axisX, yForFifths(distance.toDouble()));
      final minorAxis = Offset(axisX + 18, yForFifths(distance.toDouble()));
      final majorPoint = Offset.lerp(majorCircle, majorAxis, progress)!;
      final minorPoint = Offset.lerp(minorCircle, minorAxis, progress)!;

      final spokeStart = Offset.lerp(
        center,
        Offset(axisX, majorPoint.dy),
        progress,
      )!;
      canvas
        ..drawLine(spokeStart, majorPoint, spokePaint)
        ..drawCircle(
          majorPoint,
          _majorAnchorRadius,
          Paint()
            ..style = .fill
            ..color = palette.anchorFill,
        )
        ..drawCircle(
          majorPoint,
          _majorAnchorRadius,
          Paint()
            ..style = .stroke
            ..strokeWidth = 2
            ..color = palette.anchorStroke,
        )
        ..drawCircle(
          minorPoint,
          _minorAnchorRadius,
          Paint()
            ..style = .fill
            ..color = palette.anchorFill,
        )
        ..drawCircle(
          minorPoint,
          _minorAnchorRadius,
          Paint()
            ..style = .stroke
            ..strokeWidth = 1.75
            ..color = palette.secondaryText,
        );

      final labelAlpha = (0.35 + progress * 0.65).clamp(0.0, 1.0);
      if (displayOptions.showMajorLabels) {
        _drawText(
          canvas,
          majorKey.format(notationSystem),
          Offset.lerp(
            center + _unit(angle) * labelRadius,
            majorAxis - const Offset(38, 0),
            progress,
          )!,
          TextStyle(
            color: palette.primaryText.withValues(alpha: labelAlpha),
            fontSize: 15 - progress * 2,
            fontWeight: .w700,
          ),
          backgroundColor: palette.labelBackground.withValues(
            alpha: labelAlpha,
          ),
        );
      }
      if (displayOptions.showMinorLabels) {
        _drawText(
          canvas,
          minorKey.format(notationSystem),
          Offset.lerp(
            center + _unit(angle) * innerRadius,
            minorAxis + const Offset(28, 0),
            progress,
          )!,
          TextStyle(
            color: palette.secondaryText.withValues(alpha: labelAlpha),
            fontSize: 13 - progress,
            fontWeight: .w600,
          ),
          backgroundColor: palette.labelBackground.withValues(
            alpha: labelAlpha,
          ),
        );
      }
    }
  }

  Path _morphedFifthsArcPath({
    required Offset center,
    required double radius,
    required double axisX,
    required double Function(double distance) yForFifths,
    required double progress,
    required double startDistance,
    required double endDistance,
  }) {
    final path = Path();
    const segments = 48;
    for (var i = 0; i <= segments; i++) {
      final unit = i / segments;
      final distance = startDistance + (endDistance - startDistance) * unit;
      final angle = distance * math.pi / 6 - math.pi / 2;
      final circlePoint = center + _unit(angle) * radius;
      final axisPoint = Offset(axisX, yForFifths(distance));
      final point = Offset.lerp(circlePoint, axisPoint, progress)!;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    return path;
  }

  void _drawTimelineVector(
    Canvas canvas,
    ModulationVector vector,
    Offset start,
    Offset startControl,
    Offset endControl,
    Offset end,
    Offset tip,
  ) {
    if ((tip - start).distance < 0.5) {
      _drawTimelineSameKeyMarker(canvas, vector, start);
      return;
    }

    final paint = Paint()
      ..style = .stroke
      ..strokeWidth = 3
      ..strokeCap = .round
      ..color = vector.colorFor(palette);

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
    if (vector.dashed) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    final direction = _normalized(tip - end);
    if (direction == .zero) return;

    final normal = _perpendicular(direction);
    final baseCenter = tip - direction * _arrowLength;
    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        baseCenter.dx + normal.dx * _arrowHalfWidth,
        baseCenter.dy + normal.dy * _arrowHalfWidth,
      )
      ..lineTo(
        baseCenter.dx - normal.dx * _arrowHalfWidth,
        baseCenter.dy - normal.dy * _arrowHalfWidth,
      )
      ..close();
    canvas.drawPath(
      arrowPath,
      Paint()
        ..style = .fill
        ..color = vector.colorFor(palette),
    );

    if (displayOptions.showVectorLabels) {
      _drawVectorLabel(
        canvas,
        vector.label,
        _cubicPoint(start, startControl, endControl, end, 0.5) +
            const Offset(20, 0),
        vector.colorFor(palette),
      );
    }
  }

  void _drawTimelineSameKeyMarker(
    Canvas canvas,
    ModulationVector vector,
    Offset center,
  ) {
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..style = .fill
        ..color = vector.colorFor(palette),
    );
  }

  void _drawTimelineKeyLabel(
    Canvas canvas,
    _TimelinePoint point,
    double progress,
  ) {
    final key = point.entry.key;
    final isMajor = key.mode == .major;
    final fillPaint = Paint()
      ..style = .fill
      ..color = palette.anchorFill;
    final strokePaint = Paint()
      ..style = .stroke
      ..strokeWidth = isMajor ? 2 : 1.75
      ..color = isMajor ? palette.anchorStroke : palette.secondaryText;

    canvas
      ..drawCircle(
        point.position,
        isMajor ? _majorAnchorRadius : _minorAnchorRadius,
        fillPaint,
      )
      ..drawCircle(
        point.position,
        isMajor ? _majorAnchorRadius : _minorAnchorRadius,
        strokePaint,
      );

    final showKeyLabel = isMajor
        ? displayOptions.showMajorLabels
        : displayOptions.showMinorLabels;
    if (showKeyLabel) {
      _drawText(
        canvas,
        key.format(notationSystem),
        point.position + const Offset(0, -22),
        TextStyle(
          color: isMajor ? palette.primaryText : palette.secondaryText,
          fontSize: 13,
          fontWeight: .w700,
        ),
        backgroundColor: palette.labelBackground,
      );
    }

    if (displayOptions.showDurationLabels) {
      _drawText(
        canvas,
        _formatDuration(point.entry.duration),
        point.position + const Offset(0, 22),
        TextStyle(
          color: palette.legendText.withValues(alpha: progress),
          fontSize: 11,
          fontWeight: .w600,
        ),
        backgroundColor: palette.vectorLabelBackground.withValues(
          alpha: progress,
        ),
      );
    }
  }

  void _drawTimelineAxisLabels(
    Canvas canvas,
    Size size,
    double chartLeft,
    double chartRight,
    double chartBottom,
    double progress,
  ) {
    _drawText(
      canvas,
      '+ fifths',
      Offset(chartLeft - 38, 24),
      TextStyle(
        color: palette.legendText.withValues(alpha: progress),
        fontSize: 12,
        fontWeight: .w700,
      ),
    );
    _drawText(
      canvas,
      '- fifths',
      Offset(chartLeft - 38, size.height - 24),
      TextStyle(
        color: palette.legendText.withValues(alpha: progress),
        fontSize: 12,
        fontWeight: .w700,
      ),
    );
    _drawText(
      canvas,
      'time',
      Offset((chartLeft + chartRight) / 2, chartBottom + 34),
      TextStyle(
        color: palette.legendText.withValues(alpha: progress),
        fontSize: 12,
        fontWeight: .w700,
      ),
    );
  }

  void _drawTimelineLegend(Canvas canvas, Size size, double progress) {
    _drawText(
      canvas,
      'key:duration',
      Offset(size.width - 72, 22),
      TextStyle(
        color: palette.legendText.withValues(alpha: progress),
        fontSize: 12,
        fontWeight: .w600,
      ),
      backgroundColor: palette.vectorLabelBackground.withValues(
        alpha: progress,
      ),
    );
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
        palette.surface.withValues(alpha: 0),
        palette.surface.withValues(alpha: 0.34),
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
        ..color = palette.chartRing,
    );
    _drawProjectedCircle(
      canvas,
      projection,
      center,
      innerRadius,
      Paint()
        ..style = .stroke
        ..strokeWidth = 1.5
        ..color = palette.chartInnerRing,
    );

    if (displayOptions.showGrid) {
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

      if (displayOptions.showMajorLabels) {
        _drawText(
          canvas,
          majorKey.format(notationSystem),
          projection.project(center + _unit(angle) * outerLabelRadius, 0),
          const TextStyle(
            color: Color(0xff222826),
            fontSize: 15,
            fontWeight: .w700,
          ),
          backgroundColor: const Color(0xf2fffcf5),
        );
      }
      if (displayOptions.showMinorLabels) {
        _drawText(
          canvas,
          minorKey.format(notationSystem),
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
      ..color = palette.chartRing;
    final innerPaint = Paint()
      ..style = .stroke
      ..strokeWidth = 1.5
      ..color = palette.chartInnerRing;

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

      if (displayOptions.showMajorLabels) {
        _drawText(
          canvas,
          majorKey.format(notationSystem),
          center + _unit(angle) * outerLabelRadius,
          const TextStyle(
            color: Color(0xff222826),
            fontSize: 15,
            fontWeight: .w700,
          ),
          backgroundColor: const Color(0xf2fffcf5),
        );
      }
      if (displayOptions.showMinorLabels) {
        _drawText(
          canvas,
          minorKey.format(notationSystem),
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
        ..color = vector.colorFor(palette);

      if (vector.dashed) {
        _drawDashedPath(canvas, vectorPath.path, paint);
      } else {
        canvas.drawPath(vectorPath.path, paint);
      }

      _drawArrowHead(canvas, vectorPath);
    }

    if (displayOptions.showVectorLabels) {
      for (final vectorPath in paths) {
        _drawVectorLabel(
          canvas,
          vectorPath.vector.label,
          vectorPath.labelPosition,
          vectorPath.vector.colorFor(palette),
        );
      }
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
    final maxDuration = vectors.isEmpty
        ? 1.0
        : vectors.fold<double>(
            0,
            (max, vector) => math.max(max, vector.duration),
          );

    for (final (index, vectorPath) in paths.indexed) {
      final elevation = compute3dVectorElevation(
        duration: vectorPath.vector.duration,
        maxDuration: maxDuration,
        index: index,
      );
      final shadowPath = _projectVectorPath(projection, vectorPath, 0);
      final shadowPaint = Paint()
        ..style = .stroke
        ..strokeWidth = 4
        ..strokeCap = .round
        ..color = palette.legendText.withValues(
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
      final elevation = compute3dVectorElevation(
        duration: vectorPath.vector.duration,
        maxDuration: maxDuration,
        index: index,
      );
      final path = _projectVectorPath(projection, vectorPath, elevation);
      final paint = Paint()
        ..style = .stroke
        ..strokeWidth = 3.6
        ..strokeCap = .round
        ..color = vector.colorFor(palette);

      if (vector.dashed) {
        _drawDashedPath(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }

      _drawArrowHead3d(canvas, projection, vectorPath, elevation);
    }

    if (displayOptions.showVectorLabels) {
      for (final (index, vectorPath) in paths.indexed) {
        _drawVectorLabel(
          canvas,
          vectorPath.vector.label,
          projection.project(
            vectorPath.labelPosition,
            compute3dVectorElevation(
              duration: vectorPath.vector.duration,
              maxDuration: maxDuration,
              index: index,
            ),
          ),
          vectorPath.vector.colorFor(palette),
        );
      }
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
      ..color = palette.chartInnerRing.withValues(alpha: 0.16 * depthProgress);

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
        ..color = vectorPath.vector.colorFor(palette),
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
    final background = Paint()..color = palette.vectorLabelBackground;
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
        ..color = vectorPath.vector.colorFor(palette),
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
      oldDelegate.vectors != vectors ||
      oldDelegate.timelineKeys != timelineKeys ||
      oldDelegate.visualizationMode != visualizationMode ||
      oldDelegate.displayOptions != displayOptions ||
      oldDelegate.depthProgress != depthProgress ||
      oldDelegate.timelineProgress != timelineProgress ||
      oldDelegate.rotationX != rotationX ||
      oldDelegate.rotationY != rotationY ||
      oldDelegate.viewPan != viewPan;
}

class _VectorLegend extends StatelessWidget {
  const _VectorLegend({required this.palette});

  final KeylineColors palette;

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        Theme.of(context).textTheme.labelLarge?.copyWith(
          color: palette.primaryText,
          fontWeight: .w700,
        ) ??
        TextStyle(
          color: palette.primaryText,
          fontSize: 13,
          fontWeight: .w700,
        );
    final labelStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: palette.legendText,
          fontWeight: .w600,
        ) ??
        TextStyle(
          color: palette.legendText,
          fontSize: 11.5,
          fontWeight: .w600,
        );

    final entries = [
      _LegendEntry(color: palette.majorToMajor, label: 'M → M'),
      _LegendEntry(color: palette.minorToMinor, label: 'm → m'),
      _LegendEntry(color: palette.majorToMinor, label: 'M → m'),
      _LegendEntry(color: palette.minorToMajor, label: 'm → M'),
    ];

    Widget legendLine({
      required Color color,
      required String label,
      bool dashed = false,
    }) {
      return Row(
        mainAxisSize: .min,
        children: [
          SizedBox(
            width: 34,
            height: 12,
            child: dashed
                ? Row(
                    children: [
                      _LegendLineSegment(color: color),
                      const SizedBox(width: 4),
                      _LegendLineSegment(color: color),
                      const SizedBox(width: 4),
                      _LegendLineSegment(color: color),
                    ],
                  )
                : Center(
                    child: Container(
                      height: 2,
                      width: 30,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: .circular(999),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Text(label, style: labelStyle),
        ],
      );
    }

    return Container(
      padding: const .fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.vectorLabelBackground.withValues(alpha: 0.96),
        borderRadius: const .all(.circular(16)),
        border: .all(color: palette.chartRing.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          Text('tonal vectors', style: titleStyle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final entry in entries)
                Row(
                  mainAxisSize: .min,
                  children: [
                    SizedBox(
                      width: 34,
                      height: 12,
                      child: Center(
                        child: Container(
                          height: 2,
                          width: 30,
                          decoration: BoxDecoration(
                            color: entry.color,
                            borderRadius: const .all(.circular(999)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(entry.label, style: labelStyle),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            width: 184,
            color: palette.chartRing.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 8),
          legendLine(color: palette.chartRing, label: 'up a fifth'),
          const SizedBox(height: 6),
          legendLine(
            color: palette.chartRing,
            label: 'down a fifth',
            dashed: true,
          ),
        ],
      ),
    );
  }
}

class _LegendLineSegment extends StatelessWidget {
  const _LegendLineSegment({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const .all(.circular(999)),
      ),
    );
  }
}

class _LegendEntry {
  const _LegendEntry({required this.color, required this.label});

  final Color color;
  final String label;
}

String _formatDuration(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

class _TimelinePoint {
  const _TimelinePoint({
    required this.entry,
    required this.time,
    required this.position,
  });

  final TimedKey entry;
  final double time;
  final Offset position;
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

double compute3dVectorElevation({
  required double duration,
  required double maxDuration,
  required int index,
}) {
  final normalizedDuration = (duration / math.max(1.0, maxDuration)).clamp(
    0.0,
    1.0,
  );

  return 24 + index * 32 + normalizedDuration * 28;
}

const _arrowLength = 14.0;
const _arrowHalfWidth = 6.0;
const _majorAnchorRadius = 6.5;
const _minorAnchorRadius = 5.25;
