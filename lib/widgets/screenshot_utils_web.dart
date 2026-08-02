import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String?> savePngBytes(
  List<int> bytes, {
  required String filename,
}) async {
  final jsBytes = Uint8List.fromList(bytes).toJS;
  final blobParts = [jsBytes].toJS;
  final blob = web.Blob(
    blobParts,
    web.BlobPropertyBag(type: 'image/png'),
  );

  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..setAttribute('download', filename)
    ..style.display = 'none';

  web.document.body!.appendChild(anchor);
  anchor
    ..click()
    ..remove();

  web.URL.revokeObjectURL(url);

  return filename;
}
