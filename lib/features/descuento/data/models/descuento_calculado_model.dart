import '../../domain/entities/descuento_calculado.dart';
import '../../domain/entities/politica_descuento.dart';

class DescuentoCalculadoModel extends DescuentoCalculado {
  const DescuentoCalculadoModel({
    required super.tieneDescuento,
    required super.precioOriginal,
    required super.precioFinal,
    required super.descuentoAplicado,
    required super.cantidad,
    required super.subtotal,
    super.politicaUsada,
  });

  factory DescuentoCalculadoModel.fromJson(Map<String, dynamic> json) {
    return DescuentoCalculadoModel(
      tieneDescuento: json['tieneDescuento'] as bool,
      precioOriginal: (json['precioOriginal'] as num).toDouble(),
      precioFinal: (json['precioFinal'] as num).toDouble(),
      descuentoAplicado: (json['descuentoAplicado'] as num).toDouble(),
      cantidad: json['cantidad'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      politicaUsada: json['politicaUsada'] != null
          ? PoliticaUsadaModel.fromJson(
              json['politicaUsada'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tieneDescuento': tieneDescuento,
      'precioOriginal': precioOriginal,
      'precioFinal': precioFinal,
      'descuentoAplicado': descuentoAplicado,
      'cantidad': cantidad,
      'subtotal': subtotal,
      'politicaUsada': politicaUsada != null
          ? (politicaUsada as PoliticaUsadaModel).toJson()
          : null,
    };
  }

  /// Convierte el modelo a entidad del dominio
  DescuentoCalculado toEntity() {
    return DescuentoCalculado(
      tieneDescuento: tieneDescuento,
      precioOriginal: precioOriginal,
      precioFinal: precioFinal,
      descuentoAplicado: descuentoAplicado,
      cantidad: cantidad,
      subtotal: subtotal,
      politicaUsada: politicaUsada,
    );
  }
}

class PoliticaUsadaModel extends PoliticaUsada {
  const PoliticaUsadaModel({
    required super.id,
    required super.nombre,
    required super.tipoDescuento,
    required super.tipoCalculo,
    required super.valorDescuento,
  });

  factory PoliticaUsadaModel.fromJson(Map<String, dynamic> json) {
    return PoliticaUsadaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      tipoDescuento: _parseTipoDescuento(json['tipoDescuento'] as String),
      tipoCalculo: _parseTipoCalculo(json['tipoCalculo'] as String),
      valorDescuento: (json['valorDescuento'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipoDescuento': _serializeTipoDescuento(tipoDescuento),
      'tipoCalculo': _serializeTipoCalculo(tipoCalculo),
      'valorDescuento': valorDescuento,
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
}
