import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:keyline/widgets/screenshot_utils_io.dart'
    if (dart.library.html) 'screenshot_utils_web.dart';

String buildCaptureFilename([DateTime? timestamp]) {
  final stamp = timestamp ?? .now().toUtc();
  final safe = stamp.toIso8601String().replaceAll(RegExp('[^A-Za-z0-9]+'), '-');
  return 'keyline-chart-$safe.png';
}

Future<String?> captureWidgetToFile(
  GlobalKey repaintBoundaryKey, {
  required String filename,
  bool includeLegend = true,
}) async {
  final boundary = repaintBoundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) return null;

  final image = await boundary.toImage(pixelRatio: 2);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return null;

  return savePngBytes(byteData.buffer.asUint8List(), filename: filename);
}
