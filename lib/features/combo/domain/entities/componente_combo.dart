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

  /// Precio unitario efectivo (usa precioEnCombo si existe, sino precio regular)
  double get precioUnitario => componenteInfo?.precioEfectivo ?? 0;

  /// Precio unitario regular (sin override del combo)
  double get precioUnitarioRegular => componenteInfo?.precio ?? 0;

  /// Precio total efectivo en el combo (precio x cantidad)
  double get precioTotal => precioUnitario * cantidad;

  /// Precio total regular sin combo (precio regular x cantidad)
  double get precioTotalRegular => precioUnitarioRegular * cantidad;

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
  final double precio;          // Precio regular del producto (desde ProductoStock)
  final double? precioEnCombo;  // Precio override dentro del combo. Null = se usa precio regular.
  final int stock;
  final bool esVariante;
  final String? imagen;
  final String? productoNombre;
  final String? varianteNombre;

  const ComponenteInfo({
    required this.id,
    required this.nombre,
    this.sku,
    required this.precio,
    this.precioEnCombo,
    required this.stock,
    required this.esVariante,
    this.imagen,
    this.productoNombre,
    this.varianteNombre,
  });

  /// Precio efectivo dentro del combo: usa override si existe, sino el precio regular
  double get precioEfectivo => precioEnCombo ?? precio;

  /// Si tiene precio diferente al regular dentro del combo
  bool get tienePrecioOverride => precioEnCombo != null && precioEnCombo != precio;

  @override
  List<Object?> get props => [
        id,
        nombre,
        sku,
        precio,
        precioEnCombo,
        stock,
        esVariante,
        imagen,
        productoNombre,
        varianteNombre,
      ];
}
