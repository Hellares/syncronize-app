import 'package:equatable/equatable.dart';

/// Entity que representa la configuración completa de códigos de una empresa
class ConfiguracionCodigos extends Equatable {
  final String id;
  final String empresaId;
  final ConfigSeccion productos;
  final ConfigSeccion variantes;
  final ConfigSeccion servicios;
  final ConfigSeccion ventas;
  final ConfigDocumentos documentos;
  final RestriccionesCodigo restricciones;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  const ConfiguracionCodigos({
    required this.id,
    required this.empresaId,
    required this.productos,
    required this.variantes,
    required this.servicios,
    required this.ventas,
    required this.documentos,
    required this.restricciones,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  @override
  List<Object?> get props => [
        id,
        empresaId,
        productos,
        variantes,
        servicios,
        ventas,
        documentos,
        restricciones,
        creadoEn,
        actualizadoEn,
      ];
}

/// Configuración de una sección (Productos, Variantes, Servicios)
class ConfigSeccion extends Equatable {
  final String codigo;
  final String separador;
  final int longitud;
  final bool? incluirSede; // Solo para productos y servicios
  final int ultimoContador;
  final String proximoCodigo;

  const ConfigSeccion({
    required this.codigo,
    required this.separador,
    required this.longitud,
    this.incluirSede,
    required this.ultimoContador,
    required this.proximoCodigo,
  });

  @override
  List<Object?> get props => [
        codigo,
        separador,
        longitud,
        incluirSede,
        ultimoContador,
        proximoCodigo,
      ];
}

/// Configuración de documentos (Facturas, Boletas, etc.)
class ConfigDocumentos extends Equatable {
  final ConfigDocumento factura;
  final ConfigDocumento boleta;
  final ConfigDocumento notaCredito;
  final ConfigDocumento notaDebito;
  final String separador;
  final int longitud;

  const ConfigDocumentos({
    required this.factura,
    required this.boleta,
    required this.notaCredito,
    required this.notaDebito,
    required this.separador,
    required this.longitud,
  });

  @override
  List<Object?> get props => [
        factura,
        boleta,
        notaCredito,
        notaDebito,
        separador,
        longitud,
      ];
}

/// Configuración de un documento específico
class ConfigDocumento extends Equatable {
  final String codigo;
  final int ultimoContador;
  final String proximoCodigo;

  const ConfigDocumento({
    required this.codigo,
    required this.ultimoContador,
    required this.proximoCodigo,
  });

  @override
  List<Object?> get props => [codigo, ultimoContador, proximoCodigo];
}

/// Restricciones de modificación de códigos
class RestriccionesCodigo extends Equatable {
  final bool puedeModificarProductoCodigo;
  final bool puedeModificarVarianteCodigo;
  final bool puedeModificarServicioCodigo;
  final String? razonProducto;
  final String? razonVariante;
  final String? razonServicio;

  const RestriccionesCodigo({
    required this.puedeModificarProductoCodigo,
    required this.puedeModificarVarianteCodigo,
    required this.puedeModificarServicioCodigo,
    this.razonProducto,
    this.razonVariante,
    this.razonServicio,
  });

  @override
  List<Object?> get props => [
        puedeModificarProductoCodigo,
        puedeModificarVarianteCodigo,
        puedeModificarServicioCodigo,
        razonProducto,
        razonVariante,
        razonServicio,
      ];
}

/// Entity para vista previa de código
class PreviewCodigo extends Equatable {
  final String codigo;
  final FormatoCodigo formato;

  const PreviewCodigo({
    required this.codigo,
    required this.formato,
  });

  @override
  List<Object?> get props => [codigo, formato];
}

/// Formato desglosado de un código
class FormatoCodigo extends Equatable {
  final String prefijo;
  final String separador;
  final String numero;
  final String? sede;

  const FormatoCodigo({
    required this.prefijo,
    required this.separador,
    required this.numero,
    this.sede,
  });

  @override
  List<Object?> get props => [prefijo, separador, numero, sede];
}

/// Enum para tipos de código
enum TipoCodigo {
  producto,
  variante,
  servicio,
  venta,
  factura,
  boleta,
  notaCredito,
  notaDebito;

  String toJson() {
    switch (this) {
      case TipoCodigo.producto:
        return 'PRODUCTO';
      case TipoCodigo.variante:
        return 'VARIANTE';
      case TipoCodigo.servicio:
        return 'SERVICIO';
      case TipoCodigo.venta:
        return 'VENTA';
      case TipoCodigo.factura:
        return 'FACTURA';
      case TipoCodigo.boleta:
        return 'BOLETA';
      case TipoCodigo.notaCredito:
        return 'NOTA_CREDITO';
      case TipoCodigo.notaDebito:
        return 'NOTA_DEBITO';
    }
  }

  static TipoCodigo fromJson(String json) {
    switch (json) {
      case 'PRODUCTO':
        return TipoCodigo.producto;
      case 'VARIANTE':
        return TipoCodigo.variante;
      case 'SERVICIO':
        return TipoCodigo.servicio;
      case 'VENTA':
        return TipoCodigo.venta;
      case 'FACTURA':
        return TipoCodigo.factura;
      case 'BOLETA':
        return TipoCodigo.boleta;
      case 'NOTA_CREDITO':
        return TipoCodigo.notaCredito;
      case 'NOTA_DEBITO':
        return TipoCodigo.notaDebito;
      default:
        throw ArgumentError('Unknown TipoCodigo: $json');
    }
  }
}
