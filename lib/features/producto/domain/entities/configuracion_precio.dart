import 'package:equatable/equatable.dart';
import 'precio_nivel.dart';

/// Entidad para configuración/plantilla de precios reutilizable
class ConfiguracionPrecio extends Equatable {
  final String id;
  final String empresaId;
  final String nombre;
  final String? descripcion;
  final bool isActive;
  final List<ConfiguracionPrecioNivel> niveles;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  final int? cantidadProductosUsando;

  const ConfiguracionPrecio({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.descripcion,
    required this.isActive,
    required this.niveles,
    required this.creadoEn,
    required this.actualizadoEn,
    this.cantidadProductosUsando,
  });

  @override
  List<Object?> get props => [
        id,
        empresaId,
        nombre,
        descripcion,
        isActive,
        niveles,
        creadoEn,
        actualizadoEn,
        cantidadProductosUsando,
      ];

  /// Descripción resumida de los niveles
  String get resumenNiveles {
    if (niveles.isEmpty) return 'Sin niveles';
    if (niveles.length == 1) return '1 nivel configurado';
    return '${niveles.length} niveles configurados';
  }

  /// Texto descriptivo para UI
  String get descripcionCompleta {
    if (descripcion != null && descripcion!.isNotEmpty) {
      return descripcion!;
    }
    return resumenNiveles;
  }
}

/// Entidad para nivel dentro de una configuración
class ConfiguracionPrecioNivel extends Equatable {
  final String id;
  final String nombre;
  final int cantidadMinima;
  final int? cantidadMaxima;
  final TipoPrecioNivel tipoPrecio;
  final double? porcentajeDesc;
  final String? descripcion;
  final int orden;

  const ConfiguracionPrecioNivel({
    required this.id,
    required this.nombre,
    required this.cantidadMinima,
    this.cantidadMaxima,
    required this.tipoPrecio,
    this.porcentajeDesc,
    this.descripcion,
    required this.orden,
  });

  @override
  List<Object?> get props => [
        id,
        nombre,
        cantidadMinima,
        cantidadMaxima,
        tipoPrecio,
        porcentajeDesc,
        descripcion,
        orden,
      ];

  /// String del rango de cantidad
  String get rangoString {
    if (cantidadMaxima == null) {
      return '$cantidadMinima+';
    }
    return '$cantidadMinima-$cantidadMaxima';
  }

  /// Descripción del descuento/precio
  String getDescripcionPrecio(double? precioBase) {
    if (tipoPrecio == TipoPrecioNivel.precioFijo) {
      return 'Precio fijo';
    } else if (porcentajeDesc != null) {
      if (precioBase != null) {
        final precioFinal = precioBase * (1 - porcentajeDesc! / 100);
        return '${porcentajeDesc!.toStringAsFixed(0)}% desc. (S/ ${precioFinal.toStringAsFixed(2)})';
      }
      return '${porcentajeDesc!.toStringAsFixed(0)}% de descuento';
    }
    return 'Sin configurar';
  }

  /// Calcula el precio final dado un precio base
  double? calcularPrecioFinal(double precioBase) {
    if (tipoPrecio == TipoPrecioNivel.precioFijo) {
      // Las configuraciones no tienen precio fijo, se define en el producto
      return null;
    } else if (porcentajeDesc != null) {
      return precioBase * (1 - porcentajeDesc! / 100);
    }
    return null;
  }
}
