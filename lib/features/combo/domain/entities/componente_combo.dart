import 'package:equatable/equatable.dart';

/// Entidad que representa un componente de un combo
/// Puede ser un producto base o una variante específica
class ComponenteCombo extends Equatable {
  final String id;
  final String comboId;
  final String? componenteProductoId; // ID del producto (si no es variante)
  final String? componenteVarianteId; // ID de la variante (si es variante específica)
  final int cantidad; // Cantidad de este componente en el combo
  final bool esPersonalizable; // Si puede ser reemplazado (para PCs ensamblables)
  final String? categoriaComponente; // "CPU", "RAM", "Almacenamiento", etc.
  final int orden; // Orden de visualización
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Información del componente (producto o variante)
  final ComponenteInfo? componenteInfo;

  const ComponenteCombo({
    required this.id,
    required this.comboId,
    this.componenteProductoId,
    this.componenteVarianteId,
    required this.cantidad,
    this.esPersonalizable = false,
    this.categoriaComponente,
    this.orden = 0,
    required this.creadoEn,
    required this.actualizadoEn,
    this.componenteInfo,
  });

  @override
  List<Object?> get props => [
        id,
        comboId,
        componenteProductoId,
        componenteVarianteId,
        cantidad,
        esPersonalizable,
        categoriaComponente,
        orden,
        creadoEn,
        actualizadoEn,
        componenteInfo,
      ];

  /// Retorna el nombre del componente
  String get nombre => componenteInfo?.nombre ?? 'Componente';

  /// Retorna el precio unitario del componente
  double get precioUnitario => componenteInfo?.precio ?? 0;

  /// Retorna el precio total (precio x cantidad)
  double get precioTotal => precioUnitario * cantidad;

  /// Retorna el stock disponible del componente
  int get stockDisponible => componenteInfo?.stock ?? 0;

  /// Verifica si el componente tiene stock suficiente
  bool get tieneStockSuficiente => stockDisponible >= cantidad;

  /// Retorna cuántos combos se pueden armar con este componente
  int get maxCombos => cantidad > 0 ? (stockDisponible ~/ cantidad) : 0;
}

/// Información básica del componente (producto o variante)
class ComponenteInfo extends Equatable {
  final String id;
  final String nombre;
  final String? sku;
  final double precio;
  final int stock;
  final bool esVariante;
  final String? imagen;
  final String? productoNombre; // Nombre del producto (cuando es variante)
  final String? varianteNombre; // Nombre de la variante específica

  const ComponenteInfo({
    required this.id,
    required this.nombre,
    this.sku,
    required this.precio,
    required this.stock,
    required this.esVariante,
    this.imagen,
    this.productoNombre,
    this.varianteNombre,
  });

  @override
  List<Object?> get props => [
        id,
        nombre,
        sku,
        precio,
        stock,
        esVariante,
        imagen,
        productoNombre,
        varianteNombre,
      ];
}
