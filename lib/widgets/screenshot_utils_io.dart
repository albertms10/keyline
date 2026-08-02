import 'dart:io';

Future<String?> savePngBytes(List<int> bytes, {required String filename}) async {
  final directory = await Directory.systemTemp.createTemp('keyline-capture');
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
