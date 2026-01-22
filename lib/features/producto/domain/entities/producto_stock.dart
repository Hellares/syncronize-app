import 'package:equatable/equatable.dart';

/// Entity para ProductoStock - Inventario por sede
class ProductoStock extends Equatable {
  final String id;
  final String sedeId;
  final String? productoId;
  final String? varianteId;
  final String empresaId;
  final int stockActual;
  final int? stockMinimo;
  final int? stockMaximo;
  final String? ubicacion;
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
    this.stockMinimo,
    this.stockMaximo,
    this.ubicacion,
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
        stockMinimo,
        stockMaximo,
        ubicacion,
        creadoEn,
        actualizadoEn,
      ];

  /// Retorna el nombre del producto/variante
  String get nombreProducto {
    if (producto != null) return producto!.nombre;
    if (variante != null) return variante!.nombre;
    return 'Producto desconocido';
  }

  /// Verifica si el stock está bajo el mínimo
  bool get esBajoMinimo {
    if (stockMinimo == null) return false;
    return stockActual <= stockMinimo!;
  }

  /// Verifica si el stock es crítico (cero)
  bool get esCritico => stockActual == 0;

  /// Porcentaje de stock respecto al máximo
  double? get porcentajeStock {
    if (stockMaximo == null || stockMaximo! == 0) return null;
    return (stockActual / stockMaximo!) * 100;
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
