import 'package:equatable/equatable.dart';

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

  // Estado de configuración de precio
  final bool precioConfigurado; // true cuando se ha establecido al menos el precio de venta

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
    this.precioConfigurado = false,
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
        precioConfigurado,
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

  /// Obtiene el precio efectivo a mostrar (con oferta si aplica)
  double? get precioEfectivo {
    if (!precioConfigurado || precio == null) return null;
    return isOfertaActiva && precioOferta != null ? precioOferta : precio;
  }

  /// Calcula el porcentaje de descuento de la oferta
  double? get porcentajeDescuento {
    if (!isOfertaActiva || precioOferta == null || precio == null || precio! == 0) return null;
    return ((precio! - precioOferta!) / precio!) * 100;
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
