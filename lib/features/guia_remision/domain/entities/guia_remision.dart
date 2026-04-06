import 'package:equatable/equatable.dart';

// Enums
enum TipoGuiaRemision { REMITENTE, TRANSPORTISTA }

enum EstadoGuiaRemision { BORRADOR, REGISTRADO, ENVIADO, ACEPTADO, RECHAZADO, ANULADO }

enum MotivoTraslado {
  VENTA,
  COMPRA,
  VENTA_CON_ENTREGA_A_TERCEROS,
  TRASLADO_ENTRE_ESTABLECIMIENTOS,
  CONSIGNACION,
  DEVOLUCION,
  RECOJO_BIENES_TRANSFORMADOS,
  IMPORTACION,
  EXPORTACION,
  OTROS,
  VENTA_SUJETA_A_CONFIRMACION,
  TRASLADO_BIENES_TRANSFORMACION,
  TRASLADO_EMISOR_ITINERANTE,
}

enum TipoTransporte { PUBLICO, PRIVADO }

extension MotivoTrasladoExt on MotivoTraslado {
  String get label {
    switch (this) {
      case MotivoTraslado.VENTA: return 'Venta';
      case MotivoTraslado.COMPRA: return 'Compra';
      case MotivoTraslado.VENTA_CON_ENTREGA_A_TERCEROS: return 'Venta con entrega a terceros';
      case MotivoTraslado.TRASLADO_ENTRE_ESTABLECIMIENTOS: return 'Traslado entre establecimientos';
      case MotivoTraslado.CONSIGNACION: return 'Consignacion';
      case MotivoTraslado.DEVOLUCION: return 'Devolucion';
      case MotivoTraslado.RECOJO_BIENES_TRANSFORMADOS: return 'Recojo bienes transformados';
      case MotivoTraslado.IMPORTACION: return 'Importacion';
      case MotivoTraslado.EXPORTACION: return 'Exportacion';
      case MotivoTraslado.OTROS: return 'Otros';
      case MotivoTraslado.VENTA_SUJETA_A_CONFIRMACION: return 'Venta sujeta a confirmacion';
      case MotivoTraslado.TRASLADO_BIENES_TRANSFORMACION: return 'Traslado para transformacion';
      case MotivoTraslado.TRASLADO_EMISOR_ITINERANTE: return 'Traslado emisor itinerante';
    }
  }

  String get codigo {
    switch (this) {
      case MotivoTraslado.VENTA: return '01';
      case MotivoTraslado.COMPRA: return '02';
      case MotivoTraslado.VENTA_CON_ENTREGA_A_TERCEROS: return '03';
      case MotivoTraslado.TRASLADO_ENTRE_ESTABLECIMIENTOS: return '04';
      case MotivoTraslado.CONSIGNACION: return '05';
      case MotivoTraslado.DEVOLUCION: return '06';
      case MotivoTraslado.RECOJO_BIENES_TRANSFORMADOS: return '07';
      case MotivoTraslado.IMPORTACION: return '08';
      case MotivoTraslado.EXPORTACION: return '09';
      case MotivoTraslado.OTROS: return '13';
      case MotivoTraslado.VENTA_SUJETA_A_CONFIRMACION: return '14';
      case MotivoTraslado.TRASLADO_BIENES_TRANSFORMACION: return '17';
      case MotivoTraslado.TRASLADO_EMISOR_ITINERANTE: return '18';
    }
  }
}

extension EstadoGuiaRemisionExt on EstadoGuiaRemision {
  String get label {
    switch (this) {
      case EstadoGuiaRemision.BORRADOR: return 'Borrador';
      case EstadoGuiaRemision.REGISTRADO: return 'Registrado';
      case EstadoGuiaRemision.ENVIADO: return 'Enviado';
      case EstadoGuiaRemision.ACEPTADO: return 'Aceptado';
      case EstadoGuiaRemision.RECHAZADO: return 'Rechazado';
      case EstadoGuiaRemision.ANULADO: return 'Anulado';
    }
  }

  bool get isTerminal => this == EstadoGuiaRemision.ACEPTADO || this == EstadoGuiaRemision.ANULADO;
  bool get puedeEnviar => this == EstadoGuiaRemision.BORRADOR || this == EstadoGuiaRemision.ENVIADO || this == EstadoGuiaRemision.RECHAZADO;
}

// Main entity
class GuiaRemision extends Equatable {
  final String id;
  final String empresaId;
  final String? sedeId;
  final String tipo; // REMITENTE, TRANSPORTISTA
  final String serie;
  final int correlativo;
  final String codigoGenerado;
  final String estado;
  final String sunatStatus;
  final DateTime fechaEmision;
  final DateTime fechaInicioTraslado;
  final String motivoTraslado;
  final String? motivoTrasladoOtrosDescripcion;
  final String? observaciones;
  final double pesoBrutoTotal;
  final String pesoBrutoUnidadMedida;
  final int? numeroBultos;
  final String? tipoTransporte;
  final String clienteTipoDocumento;
  final String clienteNumeroDocumento;
  final String clienteDenominacion;
  final String? clienteDireccion;
  final String? clienteEmail;
  final String puntoPartidaUbigeo;
  final String puntoPartidaDireccion;
  final String? puntoPartidaCodigoEstablecimientoSunat;
  final String puntoLlegadaUbigeo;
  final String puntoLlegadaDireccion;
  final String? puntoLlegadaCodigoEstablecimientoSunat;
  final String? transportistaPlacaNumero;
  final String? transportistaDenominacion;
  final String? conductorNombre;
  final String? conductorApellidos;
  final String? conductorNumeroLicencia;
  final String? sunatHash;
  final String? sunatXmlUrl;
  final String? sunatPdfUrl;
  final String? sunatCdrUrl;
  final String? cadenaQR;
  final String? enlaceProveedor;
  final String? errorProveedor;
  final int intentosEnvio;
  final String? ventaId;
  final String? compraId;
  final String? transferenciaId;
  final String? devolucionId;
  final DateTime creadoEn;
  // Nested
  final Map<String, dynamic>? sede;
  final Map<String, dynamic>? venta;
  final Map<String, dynamic>? compra;
  final Map<String, dynamic>? transferencia;
  final Map<String, dynamic>? devolucion;
  final List<GuiaRemisionDetalle> detalles;
  final List<GuiaRemisionDocRelacionado> documentosRelacionados;

  const GuiaRemision({
    required this.id,
    required this.empresaId,
    this.sedeId,
    required this.tipo,
    required this.serie,
    required this.correlativo,
    required this.codigoGenerado,
    required this.estado,
    required this.sunatStatus,
    required this.fechaEmision,
    required this.fechaInicioTraslado,
    required this.motivoTraslado,
    this.motivoTrasladoOtrosDescripcion,
    this.observaciones,
    required this.pesoBrutoTotal,
    this.pesoBrutoUnidadMedida = 'KGM',
    this.numeroBultos,
    this.tipoTransporte,
    required this.clienteTipoDocumento,
    required this.clienteNumeroDocumento,
    required this.clienteDenominacion,
    this.clienteDireccion,
    this.clienteEmail,
    required this.puntoPartidaUbigeo,
    required this.puntoPartidaDireccion,
    this.puntoPartidaCodigoEstablecimientoSunat,
    required this.puntoLlegadaUbigeo,
    required this.puntoLlegadaDireccion,
    this.puntoLlegadaCodigoEstablecimientoSunat,
    this.transportistaPlacaNumero,
    this.transportistaDenominacion,
    this.conductorNombre,
    this.conductorApellidos,
    this.conductorNumeroLicencia,
    this.sunatHash,
    this.sunatXmlUrl,
    this.sunatPdfUrl,
    this.sunatCdrUrl,
    this.cadenaQR,
    this.enlaceProveedor,
    this.errorProveedor,
    this.intentosEnvio = 0,
    this.ventaId,
    this.compraId,
    this.transferenciaId,
    this.devolucionId,
    required this.creadoEn,
    this.sede,
    this.venta,
    this.compra,
    this.transferencia,
    this.devolucion,
    this.detalles = const [],
    this.documentosRelacionados = const [],
  });

  String get nombreSede => (sede?['nombre'] as String?) ?? '';
  String? get documentoOrigenCodigo {
    if (venta != null) return venta!['codigo'] as String?;
    if (compra != null) return compra!['codigo'] as String?;
    if (transferencia != null) return transferencia!['codigo'] as String?;
    if (devolucion != null) return devolucion!['codigo'] as String?;
    return null;
  }

  MotivoTraslado? get motivoTrasladoEnum {
    try { return MotivoTraslado.values.firstWhere((e) => e.name == motivoTraslado); } catch (_) { return null; }
  }

  EstadoGuiaRemision get estadoEnum {
    try { return EstadoGuiaRemision.values.firstWhere((e) => e.name == estado); } catch (_) { return EstadoGuiaRemision.BORRADOR; }
  }

  @override
  List<Object?> get props => [id];
}

class GuiaRemisionDetalle extends Equatable {
  final String id;
  final String? productoId;
  final String? varianteId;
  final String unidadMedida;
  final String? codigo;
  final String descripcion;
  final double cantidad;
  final Map<String, dynamic>? producto;
  final Map<String, dynamic>? variante;

  const GuiaRemisionDetalle({
    required this.id,
    this.productoId,
    this.varianteId,
    this.unidadMedida = 'NIU',
    this.codigo,
    required this.descripcion,
    required this.cantidad,
    this.producto,
    this.variante,
  });

  String get nombreProducto {
    if (variante != null) return '${producto?['nombre'] ?? ''} - ${variante!['nombre']}';
    return producto?['nombre'] as String? ?? descripcion;
  }

  @override
  List<Object?> get props => [id];
}

class GuiaRemisionDocRelacionado extends Equatable {
  final String id;
  final String tipo;
  final String serie;
  final int numero;

  const GuiaRemisionDocRelacionado({
    required this.id,
    required this.tipo,
    required this.serie,
    required this.numero,
  });

  String get tipoLabel {
    switch (tipo) {
      case '01': return 'Factura';
      case '03': return 'Boleta';
      case '09': return 'GRE Remitente';
      case '31': return 'GRE Transportista';
      default: return 'Documento';
    }
  }

  String get codigoCompleto => '$serie-${numero.toString().padLeft(8, '0')}';

  @override
  List<Object?> get props => [id];
}

// Catalog entities
class VehiculoEmpresa extends Equatable {
  final String id;
  final String placaNumero;
  final String? marca;
  final String? modelo;
  final String? tipo;
  final double? capacidadTM;
  final String? tuc;
  final bool isActive;

  const VehiculoEmpresa({
    required this.id,
    required this.placaNumero,
    this.marca,
    this.modelo,
    this.tipo,
    this.capacidadTM,
    this.tuc,
    this.isActive = true,
  });

  String get descripcion => '$placaNumero${marca != null ? ' ($marca $modelo)' : ''}';

  @override
  List<Object?> get props => [id];
}

class ConductorEmpresa extends Equatable {
  final String id;
  final String tipoDocumento;
  final String numeroDocumento;
  final String nombre;
  final String apellidos;
  final String numeroLicencia;
  final String? categoriaLicencia;
  final bool isActive;

  const ConductorEmpresa({
    required this.id,
    this.tipoDocumento = '1',
    required this.numeroDocumento,
    required this.nombre,
    required this.apellidos,
    required this.numeroLicencia,
    this.categoriaLicencia,
    this.isActive = true,
  });

  String get nombreCompleto => '$nombre $apellidos';

  @override
  List<Object?> get props => [id];
}

class TransportistaEmpresa extends Equatable {
  final String id;
  final String ruc;
  final String razonSocial;
  final String? direccion;
  final String? telefono;
  final String? email;
  final String? registroMtc;
  final bool isActive;

  const TransportistaEmpresa({
    required this.id,
    required this.ruc,
    required this.razonSocial,
    this.direccion,
    this.telefono,
    this.email,
    this.registroMtc,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id];
}
