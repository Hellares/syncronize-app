import 'package:equatable/equatable.dart';

class ConfiguracionDocumentos extends Equatable {
  final String id;
  final String empresaId;
  final String? logoUrl;
  final String? nombreComercial;
  // Datos fiscales: vienen dinámicamente del backend (Empresa/Sede), no de la BD
  final String? ruc;
  final String? direccion;
  final String? telefono;
  final String? email;
  // Estilos visuales
  final String colorPrimario;
  final String colorSecundario;
  final String colorTexto;
  final String textoPiePagina;
  /// Pie SOLO para tickets de VENTA (ej. política de devoluciones);
  /// null = usa textoPiePagina.
  final String? textoPieVenta;
  /// Términos SOLO para tickets/documentos de SERVICIO;
  /// null = usa textoPiePagina.
  final String? textoPieServicio;
  final bool mostrarPaginacion;

  const ConfiguracionDocumentos({
    required this.id,
    required this.empresaId,
    this.logoUrl,
    this.nombreComercial,
    this.ruc,
    this.direccion,
    this.telefono,
    this.email,
    this.colorPrimario = '#1565C0',
    this.colorSecundario = '#1E88E5',
    this.colorTexto = '#333333',
    this.textoPiePagina = 'Gracias por su preferencia',
    this.textoPieVenta,
    this.textoPieServicio,
    this.mostrarPaginacion = true,
  });

  /// Pie efectivo para tickets de venta.
  String get pieVentaEfectivo =>
      (textoPieVenta?.trim().isNotEmpty ?? false) ? textoPieVenta! : textoPiePagina;

  /// Pie/términos efectivos para documentos de servicio.
  String get pieServicioEfectivo =>
      (textoPieServicio?.trim().isNotEmpty ?? false) ? textoPieServicio! : textoPiePagina;

  @override
  List<Object?> get props => [
        id, empresaId, logoUrl, nombreComercial,
        ruc, direccion, telefono, email,
        colorPrimario, colorSecundario, colorTexto,
        textoPiePagina, textoPieVenta, textoPieServicio, mostrarPaginacion,
      ];
}
