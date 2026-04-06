import '../../domain/entities/guia_remision.dart';

class GuiaRemisionModel extends GuiaRemision {
  const GuiaRemisionModel({
    required super.id,
    required super.empresaId,
    super.sedeId,
    required super.tipo,
    required super.serie,
    required super.correlativo,
    required super.codigoGenerado,
    required super.estado,
    required super.sunatStatus,
    required super.fechaEmision,
    required super.fechaInicioTraslado,
    required super.motivoTraslado,
    super.motivoTrasladoOtrosDescripcion,
    super.observaciones,
    required super.pesoBrutoTotal,
    super.pesoBrutoUnidadMedida,
    super.numeroBultos,
    super.tipoTransporte,
    required super.clienteTipoDocumento,
    required super.clienteNumeroDocumento,
    required super.clienteDenominacion,
    super.clienteDireccion,
    super.clienteEmail,
    required super.puntoPartidaUbigeo,
    required super.puntoPartidaDireccion,
    super.puntoPartidaCodigoEstablecimientoSunat,
    required super.puntoLlegadaUbigeo,
    required super.puntoLlegadaDireccion,
    super.puntoLlegadaCodigoEstablecimientoSunat,
    super.transportistaPlacaNumero,
    super.transportistaDenominacion,
    super.conductorNombre,
    super.conductorApellidos,
    super.conductorNumeroLicencia,
    super.sunatHash,
    super.sunatXmlUrl,
    super.sunatPdfUrl,
    super.sunatCdrUrl,
    super.cadenaQR,
    super.enlaceProveedor,
    super.errorProveedor,
    super.intentosEnvio,
    super.ventaId,
    super.compraId,
    super.transferenciaId,
    super.devolucionId,
    required super.creadoEn,
    super.sede,
    super.venta,
    super.compra,
    super.transferencia,
    super.devolucion,
    super.detalles,
    super.documentosRelacionados,
  });

  factory GuiaRemisionModel.fromJson(Map<String, dynamic> json) {
    final detallesJson = json['detalles'] as List?;
    final docsJson = json['documentosRelacionados'] as List?;

    return GuiaRemisionModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      sedeId: json['sedeId'] as String?,
      tipo: json['tipo'] as String,
      serie: json['serie'] as String,
      correlativo: json['correlativo'] as int,
      codigoGenerado: json['codigoGenerado'] as String,
      estado: json['estado'] as String,
      sunatStatus: json['sunatStatus'] as String? ?? 'PENDIENTE',
      fechaEmision: DateTime.parse(json['fechaEmision'] as String),
      fechaInicioTraslado: DateTime.parse(json['fechaInicioTraslado'] as String),
      motivoTraslado: json['motivoTraslado'] as String,
      motivoTrasladoOtrosDescripcion: json['motivoTrasladoOtrosDescripcion'] as String?,
      observaciones: json['observaciones'] as String?,
      pesoBrutoTotal: _toDouble(json['pesoBrutoTotal']),
      pesoBrutoUnidadMedida: json['pesoBrutoUnidadMedida'] as String? ?? 'KGM',
      numeroBultos: json['numeroBultos'] as int?,
      tipoTransporte: json['tipoTransporte'] as String?,
      clienteTipoDocumento: json['clienteTipoDocumento'] as String? ?? '6',
      clienteNumeroDocumento: json['clienteNumeroDocumento'] as String? ?? '',
      clienteDenominacion: json['clienteDenominacion'] as String? ?? '',
      clienteDireccion: json['clienteDireccion'] as String?,
      clienteEmail: json['clienteEmail'] as String?,
      puntoPartidaUbigeo: json['puntoPartidaUbigeo'] as String? ?? '',
      puntoPartidaDireccion: json['puntoPartidaDireccion'] as String? ?? '',
      puntoPartidaCodigoEstablecimientoSunat: json['puntoPartidaCodigoEstablecimientoSunat'] as String?,
      puntoLlegadaUbigeo: json['puntoLlegadaUbigeo'] as String? ?? '',
      puntoLlegadaDireccion: json['puntoLlegadaDireccion'] as String? ?? '',
      puntoLlegadaCodigoEstablecimientoSunat: json['puntoLlegadaCodigoEstablecimientoSunat'] as String?,
      transportistaPlacaNumero: json['transportistaPlacaNumero'] as String?,
      transportistaDenominacion: json['transportistaDenominacion'] as String?,
      conductorNombre: json['conductorNombre'] as String?,
      conductorApellidos: json['conductorApellidos'] as String?,
      conductorNumeroLicencia: json['conductorNumeroLicencia'] as String?,
      sunatHash: json['sunatHash'] as String?,
      sunatXmlUrl: json['sunatXmlUrl'] as String?,
      sunatPdfUrl: json['sunatPdfUrl'] as String?,
      sunatCdrUrl: json['sunatCdrUrl'] as String?,
      cadenaQR: json['cadenaQR'] as String?,
      enlaceProveedor: json['enlaceProveedor'] as String?,
      errorProveedor: json['errorProveedor'] as String?,
      intentosEnvio: json['intentosEnvio'] as int? ?? 0,
      ventaId: json['ventaId'] as String?,
      compraId: json['compraId'] as String?,
      transferenciaId: json['transferenciaId'] as String?,
      devolucionId: json['devolucionId'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      sede: json['sede'] as Map<String, dynamic>?,
      venta: json['venta'] as Map<String, dynamic>?,
      compra: json['compra'] as Map<String, dynamic>?,
      transferencia: json['transferencia'] as Map<String, dynamic>?,
      devolucion: json['devolucion'] as Map<String, dynamic>?,
      detalles: detallesJson
          ?.map((e) => GuiaRemisionDetalleModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
      documentosRelacionados: docsJson
          ?.map((e) => GuiaRemisionDocRelacionadoModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

class GuiaRemisionDetalleModel extends GuiaRemisionDetalle {
  const GuiaRemisionDetalleModel({
    required super.id,
    super.productoId,
    super.varianteId,
    super.unidadMedida,
    super.codigo,
    required super.descripcion,
    required super.cantidad,
    super.producto,
    super.variante,
  });

  factory GuiaRemisionDetalleModel.fromJson(Map<String, dynamic> json) {
    return GuiaRemisionDetalleModel(
      id: json['id'] as String,
      productoId: json['productoId'] as String?,
      varianteId: json['varianteId'] as String?,
      unidadMedida: json['unidadMedida'] as String? ?? 'NIU',
      codigo: json['codigo'] as String?,
      descripcion: json['descripcion'] as String? ?? '',
      cantidad: _toDouble(json['cantidad']),
      producto: json['producto'] as Map<String, dynamic>?,
      variante: json['variante'] as Map<String, dynamic>?,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

class GuiaRemisionDocRelacionadoModel extends GuiaRemisionDocRelacionado {
  const GuiaRemisionDocRelacionadoModel({
    required super.id,
    required super.tipo,
    required super.serie,
    required super.numero,
  });

  factory GuiaRemisionDocRelacionadoModel.fromJson(Map<String, dynamic> json) {
    return GuiaRemisionDocRelacionadoModel(
      id: json['id'] as String,
      tipo: json['tipo'] as String? ?? '',
      serie: json['serie'] as String? ?? '',
      numero: json['numero'] as int? ?? 0,
    );
  }
}

class VehiculoEmpresaModel extends VehiculoEmpresa {
  const VehiculoEmpresaModel({
    required super.id,
    required super.placaNumero,
    super.marca,
    super.modelo,
    super.tipo,
    super.capacidadTM,
    super.tuc,
    super.isActive,
  });

  factory VehiculoEmpresaModel.fromJson(Map<String, dynamic> json) {
    return VehiculoEmpresaModel(
      id: json['id'] as String,
      placaNumero: json['placaNumero'] as String,
      marca: json['marca'] as String?,
      modelo: json['modelo'] as String?,
      tipo: json['tipo'] as String?,
      capacidadTM: _toDoubleNullable(json['capacidadTM']),
      tuc: json['tuc'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static double? _toDoubleNullable(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class ConductorEmpresaModel extends ConductorEmpresa {
  const ConductorEmpresaModel({
    required super.id,
    super.tipoDocumento,
    required super.numeroDocumento,
    required super.nombre,
    required super.apellidos,
    required super.numeroLicencia,
    super.categoriaLicencia,
    super.isActive,
  });

  factory ConductorEmpresaModel.fromJson(Map<String, dynamic> json) {
    return ConductorEmpresaModel(
      id: json['id'] as String,
      tipoDocumento: json['tipoDocumento'] as String? ?? '1',
      numeroDocumento: json['numeroDocumento'] as String,
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String,
      numeroLicencia: json['numeroLicencia'] as String,
      categoriaLicencia: json['categoriaLicencia'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class TransportistaEmpresaModel extends TransportistaEmpresa {
  const TransportistaEmpresaModel({
    required super.id,
    required super.ruc,
    required super.razonSocial,
    super.direccion,
    super.telefono,
    super.email,
    super.registroMtc,
    super.isActive,
  });

  factory TransportistaEmpresaModel.fromJson(Map<String, dynamic> json) {
    return TransportistaEmpresaModel(
      id: json['id'] as String,
      ruc: json['ruc'] as String,
      razonSocial: json['razonSocial'] as String,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      registroMtc: json['registroMtc'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
