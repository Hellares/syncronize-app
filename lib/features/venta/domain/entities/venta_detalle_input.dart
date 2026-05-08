import '../../../producto/domain/entities/precio_nivel.dart';

/// Modelo tipado para items del formulario de venta.
/// A diferencia de [VentaDetalle], no incluye campos calculados
/// del servidor (id, ventaId, igv, subtotal, total).
class VentaDetalleInput {
  final String? productoId;
  final String? varianteId;
  final String? servicioId;
  final String? comboId;
  final String descripcion;
  final double cantidad;
  final double precioUnitario;
  final double descuento;
  final double porcentajeIGV;
  final bool precioIncluyeIgv;
  final String tipoAfectacion;
  final double icbper;
  final int? stockDisponible;

  /// Niveles de precio configurados para este producto/variante.
  /// Se cargan al agregar el item y se usan para recalcular precio
  /// cuando cambia la cantidad. Vacío = no hay niveles configurados.
  final List<PrecioNivel> niveles;

  /// Precio base original sin aplicar nivel (para mostrar tachado en UI).
  /// null cuando aún no se cargaron niveles o no hay nivel aplicable.
  final double? precioBase;

  /// Nombre del nivel aplicado actualmente (ej. "Por Mayor").
  /// null cuando se vende a precio base.
  final String? nivelAplicado;

  /// Porcentaje de descuento aplicado por el nivel (0-100).
  final double? descuentoNivelPct;

  /// Cuando un item proviene de la expansión de un combo, este campo
  /// guarda el id del combo origen (solo client-side — no se envía al
  /// backend). Items con el mismo `origenComboId` se agrupan visualmente
  /// y se editan/eliminan juntos.
  final String? origenComboId;

  /// Nombre del combo origen para display (ej. "Combo: Pack Familiar").
  final String? origenComboNombre;

  const VentaDetalleInput({
    this.productoId,
    this.varianteId,
    this.servicioId,
    this.comboId,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    this.descuento = 0,
    this.porcentajeIGV = 18.0,
    this.precioIncluyeIgv = false,
    this.tipoAfectacion = '10',
    this.icbper = 0,
    this.stockDisponible,
    this.niveles = const [],
    this.precioBase,
    this.nivelAplicado,
    this.descuentoNivelPct,
    this.origenComboId,
    this.origenComboNombre,
  });

  bool get exceedsStock => stockDisponible != null && cantidad > stockDisponible!;

  double get subtotalBruto => cantidad * precioUnitario - descuento;

  double get subtotal {
    if (precioIncluyeIgv) {
      return subtotalBruto / (1 + porcentajeIGV / 100);
    }
    return subtotalBruto;
  }

  double get igv => subtotal * (porcentajeIGV / 100);

  double get total {
    final base = precioIncluyeIgv ? subtotalBruto : subtotal + igv;
    return base + icbper;
  }

  Map<String, dynamic> toMap() => {
        if (productoId != null) 'productoId': productoId,
        if (varianteId != null) 'varianteId': varianteId,
        if (servicioId != null) 'servicioId': servicioId,
        if (comboId != null) 'comboId': comboId,
        'descripcion': descripcion,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        if (descuento > 0) 'descuento': descuento,
        'porcentajeIGV': porcentajeIGV,
        'precioIncluyeIgv': precioIncluyeIgv,
        'tipoAfectacion': tipoAfectacion,
        if (icbper > 0) 'icbper': icbper,
        if (origenComboId != null) 'origenComboId': origenComboId,
        if (origenComboNombre != null) 'origenComboNombre': origenComboNombre,
      };

  VentaDetalleInput copyWith({
    String? productoId,
    String? varianteId,
    String? servicioId,
    String? comboId,
    String? descripcion,
    double? cantidad,
    double? precioUnitario,
    double? descuento,
    double? porcentajeIGV,
    bool? precioIncluyeIgv,
    String? tipoAfectacion,
    double? icbper,
    int? stockDisponible,
    List<PrecioNivel>? niveles,
    double? precioBase,
    String? nivelAplicado,
    double? descuentoNivelPct,
    String? origenComboId,
    String? origenComboNombre,
    bool clearNivelAplicado = false,
    bool clearPrecioBase = false,
  }) {
    return VentaDetalleInput(
      productoId: productoId ?? this.productoId,
      varianteId: varianteId ?? this.varianteId,
      servicioId: servicioId ?? this.servicioId,
      comboId: comboId ?? this.comboId,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      descuento: descuento ?? this.descuento,
      porcentajeIGV: porcentajeIGV ?? this.porcentajeIGV,
      precioIncluyeIgv: precioIncluyeIgv ?? this.precioIncluyeIgv,
      tipoAfectacion: tipoAfectacion ?? this.tipoAfectacion,
      icbper: icbper ?? this.icbper,
      stockDisponible: stockDisponible ?? this.stockDisponible,
      niveles: niveles ?? this.niveles,
      precioBase: clearPrecioBase ? null : (precioBase ?? this.precioBase),
      nivelAplicado:
          clearNivelAplicado ? null : (nivelAplicado ?? this.nivelAplicado),
      descuentoNivelPct: clearNivelAplicado
          ? null
          : (descuentoNivelPct ?? this.descuentoNivelPct),
      origenComboId: origenComboId ?? this.origenComboId,
      origenComboNombre: origenComboNombre ?? this.origenComboNombre,
    );
  }

  /// Selecciona el nivel aplicable más específico para una cantidad dada.
  /// Devuelve `null` si ningún nivel aplica.
  static PrecioNivel? nivelAplicableParaCantidad(
    List<PrecioNivel> niveles,
    double cantidad,
  ) {
    if (niveles.isEmpty) return null;
    final cantidadInt = cantidad.floor();
    final aplicables = niveles
        .where((n) => n.isActive && n.aplicaParaCantidad(cantidadInt))
        .toList();
    if (aplicables.isEmpty) return null;
    // El más específico = mayor cantidadMinima
    aplicables.sort((a, b) => b.cantidadMinima.compareTo(a.cantidadMinima));
    return aplicables.first;
  }

  /// Recalcula `precioUnitario`, `nivelAplicado` y `descuentoNivelPct`
  /// usando los niveles cacheados sobre el `precioBase` (o el actual
  /// `precioUnitario` si no hay precioBase aún registrado).
  ///
  /// Si no hay nivel aplicable, vuelve al precio base.
  VentaDetalleInput recalcularPrecioPorNiveles(double cantidad) {
    final base = precioBase ?? precioUnitario;
    final nivel = nivelAplicableParaCantidad(niveles, cantidad);

    if (nivel == null) {
      return copyWith(
        cantidad: cantidad,
        precioUnitario: base,
        precioBase: base,
        clearNivelAplicado: true,
      );
    }

    final precioConNivel = nivel.calcularPrecioFinal(base);
    final descuentoPct = nivel.calcularDescuentoPorcentaje(base);
    return copyWith(
      cantidad: cantidad,
      precioUnitario: precioConNivel,
      precioBase: base,
      nivelAplicado: nivel.nombre,
      descuentoNivelPct: descuentoPct,
    );
  }
}
