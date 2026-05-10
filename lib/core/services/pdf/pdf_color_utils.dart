import 'package:pdf/pdf.dart';

/// Color primario por defecto cuando no hay configuración custom.
/// Equivale a Material Blue 800 (#1565C0).
const PdfColor kDefaultPdfPrimary = PdfColor.fromInt(0xFF1565C0);

/// Convierte un string hex (#RRGGBB o #AARRGGBB) a [PdfColor].
///
/// - Acepta con o sin `#`.
/// - 6 hex digits → asume alpha 0xFF.
/// - 8 hex digits → toma alpha del input.
/// - Invalid input → devuelve [fallback] (default: kDefaultPdfPrimary).
///
/// Reemplaza las 3 copias previas (`pdf_cotizacion_generator`,
/// `pdf_venta_generator`, `pdf_compra_generator`).
PdfColor hexToPdfColor(
  String hex, {
  PdfColor fallback = kDefaultPdfPrimary,
}) {
  var clean = hex.replaceFirst('#', '');
  if (clean.length == 6) clean = 'FF$clean';
  final intVal = int.tryParse(clean, radix: 16);
  if (intVal == null) return fallback;
  return PdfColor.fromInt(intVal);
}
