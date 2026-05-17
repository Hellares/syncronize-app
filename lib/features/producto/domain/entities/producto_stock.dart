import 'package:equatable/equatable.dart';

/// Motivo de liquidación (remate por debajo de precio costo).
/// Debe estar alineado con el enum `MotivoLiquidacion` del backend.
enum MotivoLiquidacion {
  fueraDeCampana,
  sinRotacion,
  proximoAVencer,
  descontinuado,
  otro,
}

extension MotivoLiquidacionX on MotivoLiquidacion {
  String get apiValue {
    switch (this) {
      case MotivoLiquidacion.fueraDeCampana:
        return 'FUERA_DE_CAMPANA';
      case MotivoLiquidacion.sinRotacion:
        return 'SIN_ROTACION';
      case MotivoLiquidacion.proximoAVencer:
        return 'PROXIMO_A_VENCER';
      case MotivoLiquidacion.descontinuado:
        return 'DESCONTINUADO';
      case MotivoLiquidacion.otro:
        return 'OTRO';
    }
  }

  String get label {
    switch (this) {
      case MotivoLiquidacion.fueraDeCampana:
        return 'Fuera de campaña';
      case MotivoLiquidacion.sinRotacion:
        return 'Sin rotación';
      case MotivoLiquidacion.proximoAVencer:
        return 'Próximo a vencer';
      case MotivoLiquidacion.descontinuado:
        return 'Descontinuado';
      case MotivoLiquidacion.otro:
        return 'Otro';
    }
  }

  static MotivoLiquidacion? fromApi(String? value) {
    if (value == null) return null;
    for (final m in MotivoLiquidacion.values) {
      if (m.apiValue == value) return m;
    }
    return null;
  }
}

/// Entity para ProductoStock - Inventario y precios por sede
class ProductoStock extends Equatable {
  final String id;
  final String sedeId;
  final String? productoId;
  final String? varianteId;
  final String empresaId;

  // ========== STOCK FÍSICO ==========
  final int stockActual; // Stock físico total en almacén

  // ========== RESERVAS ==========
  final int stockReservado; // Reservado para transferencias aprobadas
  final int stockReservadoVenta; // Apartado por clientes (pre-ventas, pedidos)

  // ========== MERMA Y ESTADO ==========
  final int stockDanado; // Productos defectuosos/dañados (no vendibles)
  final int stockEnGarantia; // Productos en proceso de garantía/reparación

  // ========== CONFIGURACIÓN ==========
  final int? stockMinimo;
  final int? stockMaximo;
  final String? ubicacion;

  // Precios por sede
  final double? precio; // Precio de venta en esta sede
  final double? precioCosto; // Precio de costo en esta sede
  final double? precioOferta; // Precio de oferta específico de la sede

  // Control de ofertas por sede
  final bool enOferta;
  final DateTime? fechaInicioOferta;
  final DateTime? fechaFinOferta;

  // Liquidación (remate bajo costo con motivo y autorización gerencial)
  final bool enLiquidacion;
  final double? precioLiquidacion;
  final MotivoLiquidacion? motivoLiquidacion;
  final String? observacionesLiquidacion;
  final DateTime? fechaInicioLiquidacion;
  final DateTime? fechaFinLiquidacion;
  final String? liquidacionAutorizadaPorId;

  // Estado de configuración de precio
  final bool precioConfigurado; // true cuando se ha establecido al menos el precio de venta
  final bool precioIncluyeIgv; // true cuando el precio de venta ya incluye IGV

  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Relaciones
  final SedeStock? sede;
  final ProductoStockInfo? producto;
  final VarianteStockInfo? variante;

  const ProductoStock({
    required this.id,
    required this.sedeId,
    this.productoId,
    this.varianteId,
    required this.empresaId,
    required this.stockActual,
    this.stockReservado = 0,
    this.stockReservadoVenta = 0,
    this.stockDanado = 0,
    this.stockEnGarantia = 0,
    this.stockMinimo,
    this.stockMaximo,
    this.ubicacion,
    this.precio,
    this.precioCosto,
    this.precioOferta,
    this.enOferta = false,
    this.fechaInicioOferta,
    this.fechaFinOferta,
    this.enLiquidacion = false,
    this.precioLiquidacion,
    this.motivoLiquidacion,
    this.observacionesLiquidacion,
    this.fechaInicioLiquidacion,
    this.fechaFinLiquidacion,
    this.liquidacionAutorizadaPorId,
    this.precioConfigurado = false,
    this.precioIncluyeIgv = true,
    required this.creadoEn,
    required this.actualizadoEn,
    this.sede,
    this.producto,
    this.variante,
  });

  @override
  List<Object?> get props => [
        id,
        sedeId,
        productoId,
        varianteId,
        empresaId,
        stockActual,
        stockReservado,
        stockReservadoVenta,
        stockDanado,
        stockEnGarantia,
        stockMinimo,
        stockMaximo,
        ubicacion,
        precio,
        precioCosto,
        precioOferta,
        enOferta,
        fechaInicioOferta,
        fechaFinOferta,
        enLiquidacion,
        precioLiquidacion,
        motivoLiquidacion,
        observacionesLiquidacion,
        fechaInicioLiquidacion,
        fechaFinLiquidacion,
        liquidacionAutorizadaPorId,
        precioConfigurado,
        precioIncluyeIgv,
        creadoEn,
        actualizadoEn,
      ];

  /// Retorna el nombre del producto/variante
  String get nombreProducto {
    if (producto != null) return producto!.nombre;
    if (variante != null) return variante!.nombre;
    return 'Producto desconocido';
  }

  // ========== CÁLCULOS DE STOCK ==========

  /// Stock disponible para TRANSFERIR (ignora dañados y en garantía)
  int get stockDisponible => stockActual - stockReservado;

  /// Stock disponible para VENTA (lo más importante para POS/eCommerce)
  int get stockDisponibleVenta =>
      stockActual - stockReservado - stockReservadoVenta - stockDanado - stockEnGarantia;

  /// Stock total comprometido (no disponible)
  int get stockComprometido => stockReservado + stockReservadoVenta;

  /// Stock no vendible (dañado o en garantía)
  int get stockNoVendible => stockDanado + stockEnGarantia;

  // ========== VALIDACIONES ==========

  /// Verifica si el stock disponible para venta está bajo el mínimo
  bool get esBajoMinimo {
    if (stockMinimo == null) return false;
    return stockDisponibleVenta <= stockMinimo!;
  }

  /// Verifica si el stock disponible para venta es crítico (cero o negativo)
  bool get esCritico => stockDisponibleVenta <= 0;

  /// Verifica si hay stock reservado para transferencias
  bool get tieneStockReservado => stockReservado > 0;

  /// Verifica si hay stock apartado para ventas
  bool get tieneStockReservadoVenta => stockReservadoVenta > 0;

  /// Verifica si hay productos dañados
  bool get tieneStockDanado => stockDanado > 0;

  /// Verifica si hay productos en garantía
  bool get tieneStockEnGarantia => stockEnGarantia > 0;

  /// Verifica si hay algún tipo de reserva o merma
  bool get tieneIncidencias => tieneStockReservado || tieneStockReservadoVenta ||
                                tieneStockDanado || tieneStockEnGarantia;

  /// Porcentaje de stock respecto al máximo
  double? get porcentajeStock {
    if (stockMaximo == null || stockMaximo! == 0) return null;
    return (stockActual / stockMaximo!) * 100;
  }

  /// Verifica si la oferta está activa actualmente
  bool get isOfertaActiva {
    if (!enOferta || precioOferta == null) return false;

    final now = DateTime.now();

    // Si hay fecha de inicio, verificar que ya comenzó
    if (fechaInicioOferta != null && now.isBefore(fechaInicioOferta!)) {
      return false;
    }

    // Si hay fecha de fin, verificar que no terminó
    if (fechaFinOferta != null && now.isAfter(fechaFinOferta!)) {
      return false;
    }

    return true;
  }

  /// Verifica si la liquidación está activa (en ventana de fechas).
  bool get isLiquidacionActiva {
    if (!enLiquidacion || precioLiquidacion == null) return false;
    final now = DateTime.now();
    if (fechaInicioLiquidacion != null && now.isBefore(fechaInicioLiquidacion!)) return false;
    if (fechaFinLiquidacion != null && now.isAfter(fechaFinLiquidacion!)) return false;
    return true;
  }

  /// Obtiene el precio efectivo a mostrar (con liquidación/oferta si aplica).
  /// Liquidación tiene prioridad sobre oferta porque suele ser un precio
  /// menor y un evento más decisivo comercialmente.
  double? get precioEfectivo {
    if (!precioConfigurado || precio == null) return null;
    if (isLiquidacionActiva && precioLiquidacion != null) return precioLiquidacion;
    return isOfertaActiva && precioOferta != null ? precioOferta : precio;
  }

  /// Calcula el porcentaje de descuento del precio efectivo respecto al base.
  double? get porcentajeDescuento {
    final efectivo = precioEfectivo;
    if (efectivo == null || precio == null || precio! == 0 || efectivo >= precio!) return null;
    return ((precio! - efectivo) / precio!) * 100;
  }
}

/// Info de sede para stock
class SedeStock extends Equatable {
  final String id;
  final String nombre;
  final String? codigo;
  final bool isActive;

  const SedeStock({
    required this.id,
    required this.nombre,
    this.codigo,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, nombre, codigo, isActive];
}

/// Info básica del producto para stock
class ProductoStockInfo extends Equatable {
  final String id;
  final String nombre;
  final String? codigoEmpresa;
  final String? sku;

  const ProductoStockInfo({
    required this.id,
    required this.nombre,
    this.codigoEmpresa,
    this.sku,
  });

  @override
  List<Object?> get props => [id, nombre, codigoEmpresa, sku];
}

/// Info básica de variante para stock
class VarianteStockInfo extends Equatable {
  final String id;
  final String nombre;
  final String? sku;

  const VarianteStockInfo({
    required this.id,
    required this.nombre,
    this.sku,
  });

  @override
  List<Object?> get props => [id, nombre, sku];
}
