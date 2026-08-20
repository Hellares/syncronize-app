import 'package:equatable/equatable.dart';

import '../../../../core/utils/unidad_presentacion.dart';

/// Tipo de precio para niveles de volumen
enum TipoPrecioNivel {
  /// Precio fijo específico para este nivel
  precioFijo('PRECIO_FIJO'),

  /// Descuento porcentual sobre precio base
  porcentajeDescuento('PORCENTAJE_DESCUENTO');

  final String value;
  const TipoPrecioNivel(this.value);

  static TipoPrecioNivel fromString(String value) {
    return TipoPrecioNivel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TipoPrecioNivel.precioFijo,
    );
  }
}

/// Entity que representa un nivel de precio por volumen
/// Permite configurar diferentes precios según la cantidad comprada
class PrecioNivel extends Equatable {
  final String id;
  final String? productoId;
  final String? varianteId;
  final String nombre;
  final int cantidadMinima;
  final int? cantidadMaxima;
  final TipoPrecioNivel tipoPrecio;
  final double? precio;
  final double? porcentajeDesc;
  final String? descripcion;
  final int orden;
  final bool isActive;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  const PrecioNivel({
    required this.id,
    this.productoId,
    this.varianteId,
    required this.nombre,
    required this.cantidadMinima,
    this.cantidadMaxima,
    required this.tipoPrecio,
    this.precio,
    this.porcentajeDesc,
    this.descripcion,
    required this.orden,
    required this.isActive,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  /// Verifica si este nivel aplica para la cantidad dada
  bool aplicaParaCantidad(int cantidad) {
    if (cantidad < cantidadMinima) return false;
    if (cantidadMaxima != null && cantidad > cantidadMaxima!) return false;
    return true;
  }

  /// Calcula el precio final para este nivel dado un precio base
  double calcularPrecioFinal(double precioBase) {
    if (tipoPrecio == TipoPrecioNivel.precioFijo) {
      return precio ?? precioBase;
    } else {
      // PORCENTAJE_DESCUENTO
      final descuento = porcentajeDesc ?? 0;
      return precioBase * (1 - descuento / 100);
    }
  }

  /// Calcula el descuento aplicado en porcentaje
  double calcularDescuentoPorcentaje(double precioBase) {
    if (tipoPrecio == TipoPrecioNivel.precioFijo && precio != null) {
      return ((precioBase - precio!) / precioBase) * 100;
    } else {
      return porcentajeDesc ?? 0;
    }
  }

  /// Obtiene el rango de cantidades como string, en unidad de VENTA.
  ///
  /// ⚠️ En un producto con presentación esto miente: un granel en gramos con
  /// "desde 3 kg" dice "3000+ unidades". Usá [rangoTexto] cuando tengas la
  /// presentación a mano; este getter queda para lo que se vende por unidad.
  String get rangoString {
    if (cantidadMaxima != null) {
      return '$cantidadMinima - $cantidadMaxima unidades';
    } else {
      return '$cantidadMinima+ unidades';
    }
  }

  /// El rango en la unidad en la que se le habla al usuario: "3 - 10 kg".
  ///
  /// 🔴 `cantidadMinima` se guarda SIEMPRE en unidad de venta, porque es contra
  /// la cantidad de la línea que el backend la compara. En un granel en gramos
  /// eso son 3000, y mostrarlo crudo hace pensar que el mayoreo arranca en 3000
  /// kilos.
  String rangoTexto(UnidadPresentacion u) {
    if (!u.activa) return rangoString;
    // El símbolo va UNA vez y al final: "3 kg - 10 kg" lo repite sin agregar
    // nada, y el rango es justo lo que se lee de un vistazo.
    if (cantidadMaxima == null) return '${u.cantidadTexto(cantidadMinima)}+';
    final min = u.cantidadTexto(cantidadMinima, conSimbolo: false);
    return '$min - ${u.cantidadTexto(cantidadMaxima!)}';
  }

  /// El precio del nivel en la unidad en la que se habla: "S/ 8.00/kg".
  /// Null en los niveles porcentuales, que no tienen precio propio.
  String? precioTexto(UnidadPresentacion u) =>
      precio == null ? null : u.precioTexto(precio!);

  /// Obtiene una descripción del descuento/precio
  String getDescripcionPrecio(double? precioBase) {
    if (tipoPrecio == TipoPrecioNivel.precioFijo) {
      return 'S/ ${precio?.toStringAsFixed(2) ?? '0.00'}';
    } else {
      final descuento = porcentajeDesc?.toStringAsFixed(1) ?? '0';
      if (precioBase != null) {
        final precioFinal = calcularPrecioFinal(precioBase);
        return '$descuento% desc. (S/ ${precioFinal.toStringAsFixed(2)})';
      }
      return '$descuento% de descuento';
    }
  }

  @override
  List<Object?> get props => [
        id,
        productoId,
        varianteId,
        nombre,
        cantidadMinima,
        cantidadMaxima,
        tipoPrecio,
        precio,
        porcentajeDesc,
        descripcion,
        orden,
        isActive,
        creadoEn,
        actualizadoEn,
      ];
}

/// Resultado del cálculo de precio según cantidad
class CalculoPrecioResult extends Equatable {
  final double precioUnitario;
  final String nivelAplicado;
  final double descuentoAplicado;
  final double precioBase;

  const CalculoPrecioResult({
    required this.precioUnitario,
    required this.nivelAplicado,
    required this.descuentoAplicado,
    required this.precioBase,
  });

  /// Calcula el ahorro total
  double get ahorroTotal => precioBase - precioUnitario;

  /// Calcula el ahorro por unidad
  double get ahorroPorUnidad => precioBase - precioUnitario;

  @override
  List<Object?> get props => [
        precioUnitario,
        nivelAplicado,
        descuentoAplicado,
        precioBase,
      ];
}
