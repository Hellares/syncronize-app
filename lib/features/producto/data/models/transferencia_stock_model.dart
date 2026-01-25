import '../../domain/entities/transferencia_stock.dart';

class TransferenciaStockModel extends TransferenciaStock {
  const TransferenciaStockModel({
    required super.id,
    required super.empresaId,
    required super.sedeOrigenId,
    required super.sedeDestinoId,
    required super.codigo,
    required super.estado,
    super.totalItems,
    super.itemsAprobados,
    super.itemsRechazados,
    super.itemsRecibidos,
    super.motivo,
    super.observaciones,
    required super.solicitadoPor,
    super.aprobadoPor,
    super.recibidoPor,
    super.fechaAprobacion,
    super.fechaEnvio,
    super.fechaRecepcion,
    required super.creadoEn,
    required super.actualizadoEn,
    super.sedeOrigen,
    super.sedeDestino,
    super.items,
  });

  factory TransferenciaStockModel.fromJson(Map<String, dynamic> json) {
    return TransferenciaStockModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      sedeOrigenId: json['sedeOrigenId'] as String,
      sedeDestinoId: json['sedeDestinoId'] as String,
      codigo: json['codigo'] as String,
      estado: EstadoTransferencia.fromString(json['estado'] as String),
      totalItems: _toInt(json['totalItems']),
      itemsAprobados: _toInt(json['itemsAprobados']),
      itemsRechazados: _toInt(json['itemsRechazados']),
      itemsRecibidos: _toInt(json['itemsRecibidos']),
      motivo: json['motivo'] as String?,
      observaciones: json['observaciones'] as String?,
      solicitadoPor: json['solicitadoPor'] as String,
      aprobadoPor: json['aprobadoPor'] as String?,
      recibidoPor: json['recibidoPor'] as String?,
      fechaAprobacion: json['fechaAprobacion'] != null
          ? DateTime.parse(json['fechaAprobacion'] as String)
          : null,
      fechaEnvio: json['fechaEnvio'] != null
          ? DateTime.parse(json['fechaEnvio'] as String)
          : null,
      fechaRecepcion: json['fechaRecepcion'] != null
          ? DateTime.parse(json['fechaRecepcion'] as String)
          : null,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      sedeOrigen: json['sedeOrigen'] != null
          ? SedeTransferenciaModel.fromJson(
              json['sedeOrigen'] as Map<String, dynamic>)
          : null,
      sedeDestino: json['sedeDestino'] != null
          ? SedeTransferenciaModel.fromJson(
              json['sedeDestino'] as Map<String, dynamic>)
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => TransferenciaStockItemModel.fromJson(
                  item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.parse(value);
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      'sedeOrigenId': sedeOrigenId,
      'sedeDestinoId': sedeDestinoId,
      'codigo': codigo,
      'estado': estado.value,
      'totalItems': totalItems,
      'itemsAprobados': itemsAprobados,
      'itemsRechazados': itemsRechazados,
      'itemsRecibidos': itemsRecibidos,
      if (motivo != null) 'motivo': motivo,
      if (observaciones != null) 'observaciones': observaciones,
      'solicitadoPor': solicitadoPor,
      if (aprobadoPor != null) 'aprobadoPor': aprobadoPor,
      if (recibidoPor != null) 'recibidoPor': recibidoPor,
      if (fechaAprobacion != null)
        'fechaAprobacion': fechaAprobacion!.toIso8601String(),
      if (fechaEnvio != null) 'fechaEnvio': fechaEnvio!.toIso8601String(),
      if (fechaRecepcion != null)
        'fechaRecepcion': fechaRecepcion!.toIso8601String(),
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }
}

class SedeTransferenciaModel extends SedeTransferencia {
  const SedeTransferenciaModel({
    required super.id,
    required super.nombre,
    super.codigo,
    super.isActive,
  });

  factory SedeTransferenciaModel.fromJson(Map<String, dynamic> json) {
    return SedeTransferenciaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (codigo != null) 'codigo': codigo,
      'isActive': isActive,
    };
  }
}

class ProductoTransferenciaInfoModel extends ProductoTransferenciaInfo {
  const ProductoTransferenciaInfoModel({
    required super.id,
    required super.nombre,
    super.codigoEmpresa,
    super.sku,
  });

  factory ProductoTransferenciaInfoModel.fromJson(Map<String, dynamic> json) {
    return ProductoTransferenciaInfoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigoEmpresa: json['codigoEmpresa'] as String?,
      sku: json['sku'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (codigoEmpresa != null) 'codigoEmpresa': codigoEmpresa,
      if (sku != null) 'sku': sku,
    };
  }
}

class VarianteTransferenciaInfoModel extends VarianteTransferenciaInfo {
  const VarianteTransferenciaInfoModel({
    required super.id,
    required super.nombre,
    super.sku,
  });

  factory VarianteTransferenciaInfoModel.fromJson(Map<String, dynamic> json) {
    return VarianteTransferenciaInfoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      sku: json['sku'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (sku != null) 'sku': sku,
    };
  }
}

class TransferenciaStockItemModel extends TransferenciaStockItem {
  const TransferenciaStockItemModel({
    required super.id,
    required super.transferenciaId,
    required super.empresaId,
    super.productoId,
    super.varianteId,
    required super.cantidadSolicitada,
    super.cantidadAprobada,
    super.cantidadEnviada,
    super.cantidadRecibida,
    required super.estado,
    super.motivo,
    super.observaciones,
    required super.creadoEn,
    required super.actualizadoEn,
    super.producto,
    super.variante,
  });

  factory TransferenciaStockItemModel.fromJson(Map<String, dynamic> json) {
    return TransferenciaStockItemModel(
      id: json['id'] as String,
      transferenciaId: json['transferenciaId'] as String,
      empresaId: json['empresaId'] as String,
      productoId: json['productoId'] as String?,
      varianteId: json['varianteId'] as String?,
      cantidadSolicitada: _toInt(json['cantidadSolicitada']),
      cantidadAprobada: json['cantidadAprobada'] != null
          ? _toInt(json['cantidadAprobada'])
          : null,
      cantidadEnviada: json['cantidadEnviada'] != null
          ? _toInt(json['cantidadEnviada'])
          : null,
      cantidadRecibida: json['cantidadRecibida'] != null
          ? _toInt(json['cantidadRecibida'])
          : null,
      estado: EstadoItemTransferencia.fromString(json['estado'] as String),
      motivo: json['motivo'] as String?,
      observaciones: json['observaciones'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      producto: json['producto'] != null
          ? ProductoTransferenciaInfoModel.fromJson(
              json['producto'] as Map<String, dynamic>)
          : null,
      variante: json['variante'] != null
          ? VarianteTransferenciaInfoModel.fromJson(
              json['variante'] as Map<String, dynamic>)
          : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.parse(value);
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transferenciaId': transferenciaId,
      'empresaId': empresaId,
      if (productoId != null) 'productoId': productoId,
      if (varianteId != null) 'varianteId': varianteId,
      'cantidadSolicitada': cantidadSolicitada,
      if (cantidadAprobada != null) 'cantidadAprobada': cantidadAprobada,
      if (cantidadEnviada != null) 'cantidadEnviada': cantidadEnviada,
      if (cantidadRecibida != null) 'cantidadRecibida': cantidadRecibida,
      'estado': estado.value,
      if (motivo != null) 'motivo': motivo,
      if (observaciones != null) 'observaciones': observaciones,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }
}
