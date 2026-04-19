import 'dart:typed_data';
import 'package:printing/printing.dart';

Future<void> savePdfImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  await Printing.layoutPdf(
    name: fileName,
    onLayout: (_) async => bytes,
  );
}