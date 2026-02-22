import 'package:equatable/equatable.dart';
import 'package:pdf/pdf.dart';

enum TipoDocumento {
  COTIZACION,
  FACTURA,
  BOLETA,
  NOTA_CREDITO,
  NOTA_DEBITO,
  GUIA_REMISION,
  TICKET_VENTA,
  ORDEN_SERVICIO;

  String get apiValue => name;

  String get label {
    switch (this) {
      case TipoDocumento.COTIZACION:
        return 'Cotizacion';
      case TipoDocumento.FACTURA:
        return 'Factura';
      case TipoDocumento.BOLETA:
        return 'Boleta';
      case TipoDocumento.NOTA_CREDITO:
        return 'Nota de Credito';
      case TipoDocumento.NOTA_DEBITO:
        return 'Nota de Debito';
      case TipoDocumento.GUIA_REMISION:
        return 'Guia de Remision';
      case TipoDocumento.TICKET_VENTA:
        return 'Ticket de Venta';
      case TipoDocumento.ORDEN_SERVICIO:
        return 'Orden de Servicio';
    }
  }

  static TipoDocumento fromString(String value) {
    return TipoDocumento.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => TipoDocumento.COTIZACION,
    );
  }
}

enum FormatoPapel {
  A4,
  TICKET_80MM,
  TICKET_58MM;

  String get apiValue => name;

  String get label {
    switch (this) {
      case FormatoPapel.A4:
        return 'A4';
      case FormatoPapel.TICKET_80MM:
        return 'Ticket 80mm';
      case FormatoPapel.TICKET_58MM:
        return 'Ticket 58mm';
    }
  }

  static FormatoPapel fromString(String value) {
    return FormatoPapel.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => FormatoPapel.A4,
    );
  }

  /// Formato para el diálogo de impresión.
  /// Para ticket usa altura de referencia (el PDF real usa Page con altura
  /// infinita que se ajusta al contenido).
  PdfPageFormat get pdfPageFormat {
    switch (this) {
      case FormatoPapel.A4:
        return PdfPageFormat.a4;
      case FormatoPapel.TICKET_80MM:
        return PdfPageFormat(80 * PdfPageFormat.mm, 297 * PdfPageFormat.mm);
      case FormatoPapel.TICKET_58MM:
        return PdfPageFormat(58 * PdfPageFormat.mm, 297 * PdfPageFormat.mm);
    }
  }

  bool get isTicket => this != FormatoPapel.A4;
}

class PlantillaDocumento extends Equatable {
  final String id;
  final String empresaId;
  final TipoDocumento tipoDocumento;
  final FormatoPapel formatoPapel;
  final String nombre;
  final double margenSuperior;
  final double margenInferior;
  final double margenIzquierdo;
  final double margenDerecho;
  final bool mostrarLogo;
  final bool mostrarDatosEmpresa;
  final bool mostrarDatosCliente;
  final bool mostrarDetalles;
  final bool mostrarTotales;
  final bool mostrarObservaciones;
  final bool mostrarCondiciones;
  final bool mostrarFirma;
  final bool mostrarCodigoQR;
  final bool mostrarPiePagina;
  final String? colorEncabezado;
  final String? colorCuerpo;

  const PlantillaDocumento({
    required this.id,
    required this.empresaId,
    required this.tipoDocumento,
    this.formatoPapel = FormatoPapel.A4,
    required this.nombre,
    this.margenSuperior = 10.0,
    this.margenInferior = 10.0,
    this.margenIzquierdo = 10.0,
    this.margenDerecho = 10.0,
    this.mostrarLogo = true,
    this.mostrarDatosEmpresa = true,
    this.mostrarDatosCliente = true,
    this.mostrarDetalles = true,
    this.mostrarTotales = true,
    this.mostrarObservaciones = true,
    this.mostrarCondiciones = true,
    this.mostrarFirma = true,
    this.mostrarCodigoQR = false,
    this.mostrarPiePagina = true,
    this.colorEncabezado,
    this.colorCuerpo,
  });

  @override
  List<Object?> get props => [
        id,
        empresaId,
        tipoDocumento,
        formatoPapel,
        nombre,
        margenSuperior,
        margenInferior,
        margenIzquierdo,
        margenDerecho,
        mostrarLogo,
        mostrarDatosEmpresa,
        mostrarDatosCliente,
        mostrarDetalles,
        mostrarTotales,
        mostrarObservaciones,
        mostrarCondiciones,
        mostrarFirma,
        mostrarCodigoQR,
        mostrarPiePagina,
        colorEncabezado,
        colorCuerpo,
      ];
}
