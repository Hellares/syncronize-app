/// La ficha capturada, metida en un PDF de UNA sola hoja.
///
/// 🔴 La hoja NO es A4: una ficha centrada en A4 le llega al cliente como un
/// documento casi vacío con una estampilla en el medio. La página se corta a la
/// proporción exacta de la captura, así el PDF se ve igual que el PNG.
///
/// Es el mismo criterio que la web (`ficha-canvas.ts`), para que la misma
/// empresa mande la misma hoja desde el celular o desde la computadora.
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// [pngBytes] es la captura del lienzo (360 px lógicos de ancho, a ×3).
///
/// [anchoMm] a 100 deja la ficha en 10 cm: con 1080 px de ancho son ~274 dpi,
/// que imprime limpio.
///
/// 🔴 `MemoryImage` LANZA si no reconoce los bytes. Acá son los nuestros —los
/// acaba de escribir `toByteData`—, pero el try/catch deja que la pantalla
/// avise en vez de tumbar el compartir.
Future<Uint8List?> fichaAPdf(Uint8List pngBytes, {double anchoMm = 100}) async {
  final pw.MemoryImage imagen;
  try {
    imagen = pw.MemoryImage(pngBytes);
  } catch (_) {
    return null;
  }

  // `MemoryImage` no promete las medidas (son `int?`): sin ellas no hay
  // proporción que respetar y la hoja saldría deformada.
  final anchoPng = imagen.width;
  final altoPng = imagen.height;
  if (anchoPng == null || altoPng == null || anchoPng <= 0 || altoPng <= 0) {
    return null;
  }

  final ancho = anchoMm * PdfPageFormat.mm;
  final alto = ancho * altoPng / anchoPng;

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(ancho, alto, marginAll: 0),
      build: (_) => pw.Image(imagen, fit: pw.BoxFit.fill),
    ),
  );
  return doc.save();
}
