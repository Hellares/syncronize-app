import 'package:pdf/pdf.dart';

import '../../../features/configuracion_documentos/domain/entities/configuracion_documento_completa.dart';
import '../../../features/configuracion_documentos/domain/entities/plantilla_documento.dart';
import 'pdf_color_utils.dart';

/// Estilo unificado para documentos PDF.
///
/// Centraliza la lectura de [ConfiguracionDocumentoCompleta] +
/// [PlantillaDocumento] que cada generador hacía manualmente con ~30
/// líneas de `documentConfig?.foo ?? defaultBar`. Cada generador llama
/// [PdfDocumentStyle.fromConfig] con sus defaults específicos
/// (márgenes, color de cuerpo, etc.) y lee fields tipados.
///
/// Ejemplos de uso:
/// ```dart
/// final style = PdfDocumentStyle.fromConfig(
///   documentConfig: documentConfig,
///   empresaNombre: empresaNombre,
///   defaultMarginMm: 10,
/// );
/// pageFormat: PdfPageFormat(595, 842, marginAll: style.marginAllPt),
/// ```
class PdfDocumentStyle {
  // ── Colores ──
  final PdfColor colorPrimario;
  final PdfColor colorCuerpo;

  // ── Márgenes en puntos PDF (ya multiplicados por PdfPageFormat.mm) ──
  final double marginTopPt;
  final double marginBottomPt;
  final double marginLeftPt;
  final double marginRightPt;

  // ── Flags de visibilidad (todos true si no hay plantilla) ──
  final bool showLogo;
  final bool showDatosEmpresa;
  final bool showDatosCliente;
  final bool showDetalles;
  final bool showTotales;
  final bool showObservaciones;
  final bool showCondiciones;
  final bool showFirma;
  final bool showPiePagina;

  // ── Formato papel ──
  final FormatoPapel formatoPapel;

  // ── Datos de empresa resueltos (config con fallbacks al param) ──
  final String empresaNombre;
  final String? empresaRuc;
  final String? empresaDireccion;
  final String? empresaTelefono;

  // ── Sede y pie de página ──
  final String? sedeNombre;
  final String? textoPiePagina;

  // ── Acceso al config raw para casos edge (logo embebido, etc.) ──
  final ConfiguracionDocumentoCompleta? raw;

  const PdfDocumentStyle({
    required this.colorPrimario,
    required this.colorCuerpo,
    required this.marginTopPt,
    required this.marginBottomPt,
    required this.marginLeftPt,
    required this.marginRightPt,
    required this.showLogo,
    required this.showDatosEmpresa,
    required this.showDatosCliente,
    required this.showDetalles,
    required this.showTotales,
    required this.showObservaciones,
    required this.showCondiciones,
    required this.showFirma,
    required this.showPiePagina,
    required this.formatoPapel,
    required this.empresaNombre,
    this.empresaRuc,
    this.empresaDireccion,
    this.empresaTelefono,
    this.sedeNombre,
    this.textoPiePagina,
    this.raw,
  });

  /// Construye el style aplicando defaults + overrides desde el
  /// `documentConfig`/`plantilla`. Los `default*Mm` se aplican cuando
  /// `plantilla.margen*` viene null (cada tipo de documento tiene
  /// distintos defaults — cotización/compra usan 10mm, venta usa 4mm).
  factory PdfDocumentStyle.fromConfig({
    ConfiguracionDocumentoCompleta? documentConfig,
    required String empresaNombre,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    PdfColor defaultPrimaryColor = kDefaultPdfPrimary,
    PdfColor defaultBodyColor = PdfColors.black,
    double defaultMarginMm = 10.0,
  }) {
    final config = documentConfig?.configuracion;
    final plantilla = documentConfig?.plantilla;

    // Colores
    final colorPrimarioStr = documentConfig?.colorPrimarioEfectivo ?? '';
    final colorPrimario = colorPrimarioStr.isEmpty
        ? defaultPrimaryColor
        : hexToPdfColor(colorPrimarioStr, fallback: defaultPrimaryColor);
    final colorCuerpoStr = documentConfig?.colorCuerpoEfectivo ?? '';
    final colorCuerpo = colorCuerpoStr.isEmpty
        ? defaultBodyColor
        : hexToPdfColor(colorCuerpoStr, fallback: defaultBodyColor);

    // Márgenes (mm → puntos)
    final mt = (plantilla?.margenSuperior ?? defaultMarginMm) *
        PdfPageFormat.mm;
    final mb = (plantilla?.margenInferior ?? defaultMarginMm) *
        PdfPageFormat.mm;
    final ml = (plantilla?.margenIzquierdo ?? defaultMarginMm) *
        PdfPageFormat.mm;
    final mr = (plantilla?.margenDerecho ?? defaultMarginMm) *
        PdfPageFormat.mm;

    // Datos empresa: config tiene prioridad sobre param
    final nombreResolvido = config?.nombreComercial ?? empresaNombre;
    final rucResolvido = config?.ruc ?? empresaRuc;
    final direccionResolvido = documentConfig?.direccionEfectiva ??
        config?.direccion ??
        empresaDireccion;
    final telefonoResolvido =
        documentConfig?.telefonoEfectivo ?? config?.telefono ?? empresaTelefono;

    return PdfDocumentStyle(
      colorPrimario: colorPrimario,
      colorCuerpo: colorCuerpo,
      marginTopPt: mt,
      marginBottomPt: mb,
      marginLeftPt: ml,
      marginRightPt: mr,
      showLogo: plantilla?.mostrarLogo ?? true,
      showDatosEmpresa: plantilla?.mostrarDatosEmpresa ?? true,
      showDatosCliente: plantilla?.mostrarDatosCliente ?? true,
      showDetalles: plantilla?.mostrarDetalles ?? true,
      showTotales: plantilla?.mostrarTotales ?? true,
      showObservaciones: plantilla?.mostrarObservaciones ?? true,
      showCondiciones: plantilla?.mostrarCondiciones ?? true,
      showFirma: plantilla?.mostrarFirma ?? true,
      showPiePagina: plantilla?.mostrarPiePagina ?? true,
      formatoPapel: plantilla?.formatoPapel ?? FormatoPapel.A4,
      empresaNombre: nombreResolvido,
      empresaRuc: rucResolvido,
      empresaDireccion: direccionResolvido,
      empresaTelefono: telefonoResolvido,
      sedeNombre: documentConfig?.sede?.nombre,
      textoPiePagina: config?.textoPiePagina,
      raw: documentConfig,
    );
  }
}
