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
    super.markupSobreCosto,
    super.estrategiaMayor,
    super.isActive,
    required super.creadoEn,
    required super.actualizadoEn,
    super.totalUsuarios,
    super.totalProductos,
    super.totalCategorias,
    super.totalUsos,
    super.productoIdsAplicables,
    super.categoriaIdsAplicables,
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
      markupSobreCosto: json['markupSobreCosto'] != null
          ? _parseDouble(json['markupSobreCosto'])
          : null,
      estrategiaMayor: _parseEstrategiaMayor(json['estrategiaMayor'] as String?),
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
      productoIdsAplicables: _parseIds(json['productosAplicables'], 'productoId'),
      categoriaIdsAplicables:
          _parseIds(json['categoriasAplicables'], 'categoriaId'),
    );
  }

  /// Extrae los IDs de una lista de relaciones (productosAplicables /
  /// categoriasAplicables) tanto del listado como del detalle del backend.
  static List<String> _parseIds(dynamic lista, String campo) {
    if (lista is! List) return const [];
    return lista
        .whereType<Map<String, dynamic>>()
        .map((e) => e[campo])
        .whereType<String>()
        .toList();
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
      'markupSobreCosto': markupSobreCosto,
      'estrategiaMayor': _serializeEstrategiaMayor(estrategiaMayor),
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
      case 'PRECIO_COSTO':
        return TipoCalculoDescuento.precioCosto;
      case 'PRECIO_MAYOR_DESDE_UNIDAD':
        return TipoCalculoDescuento.precioMayorDesdeUnidad;
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
      case TipoCalculoDescuento.precioCosto:
        return 'PRECIO_COSTO';
      case TipoCalculoDescuento.precioMayorDesdeUnidad:
        return 'PRECIO_MAYOR_DESDE_UNIDAD';
    }
  }

  static EstrategiaMayor _parseEstrategiaMayor(String? value) {
    switch (value) {
      case 'MEJOR_NIVEL':
        return EstrategiaMayor.mejorNivel;
      case 'PRIMER_NIVEL':
      default:
        return EstrategiaMayor.primerNivel;
    }
  }

  static String _serializeEstrategiaMayor(EstrategiaMayor estrategia) {
    switch (estrategia) {
      case EstrategiaMayor.primerNivel:
        return 'PRIMER_NIVEL';
      case EstrategiaMayor.mejorNivel:
        return 'MEJOR_NIVEL';
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
      markupSobreCosto: markupSobreCosto,
      estrategiaMayor: estrategiaMayor,
      isActive: isActive,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
      totalUsuarios: totalUsuarios,
      totalProductos: totalProductos,
      totalCategorias: totalCategorias,
      totalUsos: totalUsos,
      productoIdsAplicables: productoIdsAplicables,
      categoriaIdsAplicables: categoriaIdsAplicables,
    );
  }
}
