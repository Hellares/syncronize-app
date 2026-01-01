import '../../domain/entities/politica_descuento.dart';

class PoliticaDescuentoModel extends PoliticaDescuento {
  const PoliticaDescuentoModel({
    required super.id,
    required super.empresaId,
    required super.nombre,
    super.descripcion,
    required super.tipoDescuento,
    required super.tipoCalculo,
    required super.valorDescuento,
    super.descuentoMaximo,
    super.montoMinCompra,
    super.cantidadMaxUsos,
    super.fechaInicio,
    super.fechaFin,
    super.aplicarATodos,
    super.prioridad,
    super.maxFamiliaresPorTrabajador,
    super.isActive,
    required super.creadoEn,
    required super.actualizadoEn,
    super.totalUsuarios,
    super.totalProductos,
    super.totalCategorias,
    super.totalUsos,
  });

  factory PoliticaDescuentoModel.fromJson(Map<String, dynamic> json) {
    return PoliticaDescuentoModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      tipoDescuento: _parseTipoDescuento(json['tipoDescuento'] as String),
      tipoCalculo: _parseTipoCalculo(json['tipoCalculo'] as String),
      valorDescuento: _parseDouble(json['valorDescuento']),
      descuentoMaximo: json['descuentoMaximo'] != null
          ? _parseDouble(json['descuentoMaximo'])
          : null,
      montoMinCompra: json['montoMinCompra'] != null
          ? _parseDouble(json['montoMinCompra'])
          : null,
      cantidadMaxUsos: _parseInt(json['cantidadMaxUsos']),
      fechaInicio: json['fechaInicio'] != null
          ? DateTime.parse(json['fechaInicio'] as String)
          : null,
      fechaFin: json['fechaFin'] != null
          ? DateTime.parse(json['fechaFin'] as String)
          : null,
      aplicarATodos: json['aplicarATodos'] as bool? ?? false,
      prioridad: _parseInt(json['prioridad']) ?? 0,
      maxFamiliaresPorTrabajador: _parseInt(json['maxFamiliaresPorTrabajador']),
      isActive: json['isActive'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      totalUsuarios: json['_count']?['usuariosConDescuento'] != null
          ? _parseInt(json['_count']['usuariosConDescuento'])
          : null,
      totalProductos: json['_count']?['productosAplicables'] != null
          ? _parseInt(json['_count']['productosAplicables'])
          : null,
      totalCategorias: json['_count']?['categoriasAplicables'] != null
          ? _parseInt(json['_count']['categoriasAplicables'])
          : null,
      totalUsos: json['_count']?['usosHistorial'] != null
          ? _parseInt(json['_count']['usosHistorial'])
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipoDescuento': _serializeTipoDescuento(tipoDescuento),
      'tipoCalculo': _serializeTipoCalculo(tipoCalculo),
      'valorDescuento': valorDescuento,
      'descuentoMaximo': descuentoMaximo,
      'montoMinCompra': montoMinCompra,
      'cantidadMaxUsos': cantidadMaxUsos,
      'fechaInicio': fechaInicio?.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
      'aplicarATodos': aplicarATodos,
      'prioridad': prioridad,
      'maxFamiliaresPorTrabajador': maxFamiliaresPorTrabajador,
      'isActive': isActive,
    };
  }

  static TipoDescuento _parseTipoDescuento(String value) {
    switch (value) {
      case 'TRABAJADOR':
        return TipoDescuento.trabajador;
      case 'FAMILIAR_TRABAJADOR':
        return TipoDescuento.familiarTrabajador;
      case 'VIP':
        return TipoDescuento.vip;
      case 'PROMOCIONAL':
        return TipoDescuento.promocional;
      case 'LEALTAD':
        return TipoDescuento.lealtad;
      case 'CUMPLEANIOS':
        return TipoDescuento.cumpleanios;
      default:
        return TipoDescuento.trabajador;
    }
  }

  static String _serializeTipoDescuento(TipoDescuento tipo) {
    switch (tipo) {
      case TipoDescuento.trabajador:
        return 'TRABAJADOR';
      case TipoDescuento.familiarTrabajador:
        return 'FAMILIAR_TRABAJADOR';
      case TipoDescuento.vip:
        return 'VIP';
      case TipoDescuento.promocional:
        return 'PROMOCIONAL';
      case TipoDescuento.lealtad:
        return 'LEALTAD';
      case TipoDescuento.cumpleanios:
        return 'CUMPLEANIOS';
    }
  }

  static TipoCalculoDescuento _parseTipoCalculo(String value) {
    switch (value) {
      case 'PORCENTAJE':
        return TipoCalculoDescuento.porcentaje;
      case 'MONTO_FIJO':
        return TipoCalculoDescuento.montoFijo;
      default:
        return TipoCalculoDescuento.porcentaje;
    }
  }

  static String _serializeTipoCalculo(TipoCalculoDescuento tipo) {
    switch (tipo) {
      case TipoCalculoDescuento.porcentaje:
        return 'PORCENTAJE';
      case TipoCalculoDescuento.montoFijo:
        return 'MONTO_FIJO';
    }
  }

  /// Convierte el modelo a entidad del dominio
  PoliticaDescuento toEntity() {
    return PoliticaDescuento(
      id: id,
      empresaId: empresaId,
      nombre: nombre,
      descripcion: descripcion,
      tipoDescuento: tipoDescuento,
      tipoCalculo: tipoCalculo,
      valorDescuento: valorDescuento,
      descuentoMaximo: descuentoMaximo,
      montoMinCompra: montoMinCompra,
      cantidadMaxUsos: cantidadMaxUsos,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      aplicarATodos: aplicarATodos,
      prioridad: prioridad,
      maxFamiliaresPorTrabajador: maxFamiliaresPorTrabajador,
      isActive: isActive,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
      totalUsuarios: totalUsuarios,
      totalProductos: totalProductos,
      totalCategorias: totalCategorias,
      totalUsos: totalUsos,
    );
  }
}
